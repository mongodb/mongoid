# encoding: utf-8
module Mongoid
  class Criteria

    # Module providing functionality for parsing (nested) inclusion definitions.
    module Includable

      # Eager loads all the provided relations. Will load all the documents
      # into the identity map whose ids match based on the extra query for the
      # ids.
      #
      # @note This will work for embedded relations that reference another
      #   collection via belongs_to as well.
      #
      # @note Eager loading brings all the documents into memory, so there is a
      #   sweet spot on the performance gains. Internal benchmarks show that
      #   eager loading becomes slower around 100k documents, but this will
      #   naturally depend on the specific application.
      #
      # @example Eager load the provided relations.
      #   Person.includes(:posts, :game)
      #
      # @param [ Array<Symbol>, Array<Hash> ] relations The names of the relations to eager
      #   load.
      #
      # @return [ Criteria ] The cloned criteria.
      #
      # @since 2.2.0
      def includes(*relations)
        relations.flatten.each do |relation|
          if relation.is_a?(Hash)
            extract_nested_inclusion(klass, relation)
          else
            add_inclusion(klass, relation)
          end
        end
        clone
      end

      # Get a list of criteria that are to be executed for eager loading.
      #
      # @example Get the eager loading inclusions.
      #   Person.includes(:game).inclusions
      #
      # @return [ Array<Metadata> ] The inclusions.
      #
      # @since 2.2.0
      def inclusions
        @inclusions ||= []
      end

      # Set the inclusions for the criteria.
      #
      # @example Set the inclusions.
      #   criteria.inclusions = [ meta ]
      #
      # @param [ Array<Metadata> ] The inclusions.
      #
      # @return [ Array<Metadata> ] The new inclusions.
      #
      # @since 3.0.0
      def inclusions=(value)
        @inclusions = value
      end

      private

      # Add an inclusion definition to the list of inclusions for the criteria.
      #
      # @example Add an inclusion.
      #   criteria.add_inclusion(Person, :posts)
      #
      # @param [ Class, String, Symbol ] _klass The class or string/symbol of the class name.
      # @param [ Symbol ] relation The relation.
      #
      # @raise [ Errors::InvalidIncludes ] If no relation is found.
      #
      # @since 5.1.0
      def add_inclusion(_klass, relation)
        metadata = get_inclusion_metadata(_klass, relation)
        raise Errors::InvalidIncludes.new(_klass, [ relation ]) unless metadata
        inclusions.push(metadata) unless inclusions.include?(metadata)
      end

      # Extract inclusion definitions from a list.
      #
      # @example Extract the inclusions from a list.
      #   criteria.extract_relations_list(:posts, [{ :alerts => :items }])
      #
      # @param [ Symbol ] association The name of the association.
      # @param [ Array ] relations A list of associations.
      #
      # @since 5.1.0
      def extract_relations_list(association, relations)
        relations.each do |relation|
          if relation.is_a?(Hash)
            extract_nested_inclusion(association, relation)
          else
            add_inclusion(association, relation)
          end
        end
      end

      # Extract nested inclusion.
      #
      # @example Extract the inclusions from a nested definition.
      #   criteria.extract_nested_inclusion(User, { :posts => [:alerts] })
      #
      # @param [ Class, Symbol ] _klass The class for which the inclusion should be added.
      # @param [ Hash ] relation The nested inclusion.
      #
      # @since 5.1.0
      def extract_nested_inclusion(_klass, relation)
        relation.each do |association, _inclusion|
          add_inclusion(_klass, association)
          if _inclusion.is_a?(Array)
            extract_relations_list(association, _inclusion)
          else
            add_inclusion(association, _inclusion)
          end
        end
      end

      # Get the metadata for an inclusion.
      #
      # @example Get the metadata for an inclusion definition.
      #   criteria.get_inclusion_metadata(User, :posts)
      #
      # @param [ Class, Symbol, String ] _klass The class for determining the association metadata
      # @param [ Symbol  ] association The name of the association.
      #
      # @since 5.1.0
      def get_inclusion_metadata(_klass, association)
        if _klass.is_a?(Class)
          _klass.reflect_on_association(association)
        else
          _klass.to_s.classify.constantize.reflect_on_association(association)
        end
      end
    end
  end
end
