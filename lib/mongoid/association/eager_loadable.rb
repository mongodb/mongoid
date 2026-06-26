# frozen_string_literal: true

require 'mongoid/association/eager'
require 'mongoid/association/eager_load/embedded_distributor'
require 'mongoid/association/eager_load/polymorphic_preloader'
require 'mongoid/association/eager_load/lookup_pipeline'

module Mongoid
  module Association
    # This module defines the eager loading behavior for criteria.
    module EagerLoadable
      # Indicates whether the criteria has association
      # inclusions which should be eager loaded.
      #
      # @return [ true | false ] Whether to eager load.
      def eager_loadable?
        !criteria.inclusions.empty?
      end

      # Load the associations for the given documents.
      #
      # @param [ Array<Mongoid::Document> ] docs The documents.
      #
      # @return [ Array<Mongoid::Document> ] The given documents.
      def eager_load(docs)
        docs.tap do |d|
          preload(criteria.inclusions, d) if eager_loadable?
        end
      end

      # Load the associations for the given documents using $lookup.
      #
      # If any of the associated collections reside in a different cluster or
      # database than the root class, falls back to the #includes behavior and
      # logs a warning.
      #
      # @return [ Array<Mongoid::Document> ] The given documents.
      def eager_load_with_lookup
        offenders = inclusions_unreachable_by_lookup
        if offenders.any?
          offender_descriptions = offenders.map do |offender|
            "#{offender.name} (client: #{offender.klass.client_name}, database: #{offender.klass.database_name})"
          end
          Mongoid.logger.warn(
            'eager_load cannot use $lookup aggregation because the following associations ' \
            "reside in a different cluster or database than #{klass} " \
            "(client: #{klass.client_name}, database: #{klass.database_name}): " \
            "#{offender_descriptions.join(', ')}. Falling back to #includes behavior."
          )
          return eager_load(docs_for_lookup_fallback)
        end

        through_inclusions = criteria.inclusions.select do |association|
          association.is_a?(Association::Referenced::HasOneThrough) ||
            association.is_a?(Association::Referenced::HasManyThrough)
        end

        if through_inclusions.any?
          through_names = through_inclusions.map { |association| ":#{association.name}" }
          Mongoid.logger.warn(
            "#{through_names.join(', ')} are :through associations and do not support " \
            '$lookup-based eager loading. All inclusions for this query will be preloaded ' \
            'using separate queries.'
          )
          return eager_load(docs_for_lookup_fallback)
        end

        documents = preload_for_lookup(criteria)
        # A polymorphic belongs_to cannot be expressed as a $lookup: its target
        # collection varies per document. It is resolved after the roots are
        # materialized, each inclusion by its own preloader.
        criteria.inclusions.select(&:polymorphic?).each do |association|
          EagerLoad::PolymorphicPreloader.new(association, klass).preload_into(documents)
        end
        documents
      end

      # Load the associations for the given documents. This will be done
      # recursively to load the associations of the given documents'
      # associated documents.
      #
      # @param [ Array<Mongoid::Association::Relatable> ] associations
      #   The associations to load.
      # @param [ Array<Mongoid::Document> ] docs The documents.
      def preload(associations, docs)
        assoc_map = associations.group_by(&:inverse_class_name)
        docs_map = {}
        queue = [ klass.to_s ]

        # account for single-collection inheritance
        queue.push(klass.root_class.to_s) if klass != klass.root_class

        while klass = queue.shift
          next unless as = assoc_map.delete(klass)

          as.each do |assoc|
            queue << assoc.class_name

            # If this class is nested in the inclusion tree, only load documents
            # for the association above it. If there is no parent association,
            # we will include documents from the documents passed to this method.
            ds = docs
            ds = assoc.parent_inclusions.map { |p| docs_map[p].to_a }.flatten if assoc.parent_inclusions.length > 0

            res = assoc.relation.eager_loader([ assoc ], ds).run

            docs_map[assoc.name] ||= [].to_set
            docs_map[assoc.name].merge(res)
          end
        end
      end

      # Materialize the root documents with their inclusions eager-loaded by a
      # single $lookup aggregation. The pipeline is built by LookupPipeline; the
      # polymorphic inclusions it leaves out are resolved by the caller.
      #
      # @param [ Mongoid::Criteria ] criteria The criteria to load.
      #
      # @return [ Array<Mongoid::Document> ] The materialized root documents.
      def preload_for_lookup(criteria)
        pipeline = EagerLoad::LookupPipeline.new(criteria).stages
        Eager.run(criteria.inclusions, [], true, pipeline)
      end

      private

      # Returns the materialized documents to use when falling back from
      # $lookup to #includes-style preloading. Must be implemented by each
      # concrete context class.
      #
      # @return [ Array<Mongoid::Document> ] The materialized documents.
      def docs_for_lookup_fallback
        raise NotImplementedError, "#{self.class} must implement #docs_for_lookup_fallback"
      end

      # Returns the inclusions whose target class can't be reached by a $lookup
      # from the root class, which joins only within the same client and database.
      #
      # @return [ Array<Mongoid::Association::Relatable> ] The offending inclusions.
      def inclusions_unreachable_by_lookup
        # Polymorphic associations have no single resolvable klass and are not
        # loaded via $lookup, so they are never offenders.
        criteria.inclusions.reject do |association|
          association.polymorphic? || reachable_by_lookup?(association.klass)
        end
      end

      # Whether a $lookup from a query on the root class can reach the model: it
      # must live in the same client and database.
      def reachable_by_lookup?(model)
        model.client_name == klass.client_name &&
          model.database_name == klass.database_name
      end
    end
  end
end
