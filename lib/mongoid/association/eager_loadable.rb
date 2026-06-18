# frozen_string_literal: true

require 'mongoid/association/eager'

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
      # If any of the associated collections reside in a different cluster than
      # the root class, falls back to the #includes behavior and logs a warning.
      #
      # @return [ Array<Mongoid::Document> ] The given documents.
      def eager_load_with_lookup
        offenders = cross_cluster_inclusions
        if offenders.any?
          root_client = klass.client_name
          offender_list = offenders.map { |a| "#{a.name} (#{a.klass.client_name})" }.join(', ')
          Mongoid.logger.warn(
            'eager_load cannot use $lookup aggregation because the following associations ' \
            "reside in a different cluster than #{klass} (client: #{root_client}): " \
            "#{offender_list}. Falling back to #includes behavior."
          )
          return eager_load(docs_for_lookup_fallback)
        end

        through_inclusions = criteria.inclusions.select do |assoc|
          assoc.is_a?(Association::Referenced::HasOneThrough) ||
            assoc.is_a?(Association::Referenced::HasManyThrough)
        end

        if through_inclusions.any?
          names = through_inclusions.map { |a| ":#{a.name}" }.join(', ')
          Mongoid.logger.warn(
            "#{names} are :through associations and do not support $lookup-based eager " \
            'loading. All inclusions for this query will be preloaded using separate queries.'
          )
          return eager_load(docs_for_lookup_fallback)
        end

        docs = preload_for_lookup(criteria)
        # A polymorphic belongs_to cannot be expressed as a $lookup because its
        # target collection varies per document. Once the root documents are
        # materialized, a single aggregation fetches every polymorphic target.
        polymorphic_inclusions = criteria.inclusions.select(&:polymorphic?)
        preload_polymorphic(polymorphic_inclusions, docs) if polymorphic_inclusions.any?
        docs
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

      # Load the associations for the given documents. This will be done
      # recursively to load the associations of the given documents'
      # associated documents.
      #
      # @param [ Array<Mongoid::Association::Relatable> ] associations
      #   The associations to load.
      # @param [ Array<Mongoid::Document> ] docs The documents.
      def preload_for_lookup(criteria)
        inclusions = criteria.inclusions
        assoc_map = inclusions.group_by(&:inverse_class_name)
        inclusions_by_name = {}
        inclusions.each { |a| inclusions_by_name[a.name] = a }

        # match first
        pipeline = criteria.selector.to_pipeline
        # then sort, skip, limit
        pipeline.concat(criteria.options.to_pipeline_for_lookup)

        # Walk every inclusion in declaration order and let each one decide
        # what to emit: a referenced inclusion emits a $lookup (prefixed with
        # the embedded ancestor path when it lives inside an embedded doc), an
        # embedded inclusion is a passthrough, and an inclusion nested under a
        # referenced parent is emitted inside that parent's sub-pipeline by
        # create_pipeline.
        inclusions.each do |assoc|
          add_inclusion_to_pipeline(pipeline, assoc, inclusions_by_name, assoc_map)
        end

        Eager.new(inclusions, [], true, pipeline).run
      end

      # Eager loading turns each requested association into aggregation stages, but
      # not every association is fetched the same way. This is where a single
      # inclusion's strategy is settled: a plain reference becomes a top-level
      # $lookup, an embedded one travels inside its own document, a polymorphic one
      # is resolved after the roots are loaded, and one nested under a referenced
      # parent is loaded within that parent. Only the top-level cases add stages here.
      #
      # @param [ Array<Hash> ] pipeline The aggregation pipeline being built.
      # @param [ Mongoid::Association::Relatable ] assoc The inclusion to add.
      # @param [ Hash<Symbol, Mongoid::Association::Relatable> ] inclusions_by_name
      #   The inclusions indexed by association name.
      # @param [ Hash<String, Array<Mongoid::Association::Relatable>> ] assoc_map
      #   The inclusions grouped by inverse class name, used to nest children.
      def add_inclusion_to_pipeline(pipeline, assoc, inclusions_by_name, assoc_map)
        # An embedded inclusion rides inside its document; it needs no $lookup.
        return if assoc.polymorphic?
        return if assoc.embedded?

        # A referenced parent already nests this inclusion in its sub-pipeline.
        parent = inclusions_by_name[assoc.parent_inclusions.first]
        return if parent && !parent.embedded?

        chains = embedded_ancestor_chains(assoc, inclusions_by_name)
        return pipeline << create_pipeline(assoc, assoc_map.dup) if chains.empty?

        # The same inclusion can sit under several embedded parents (e.g. two
        # embeds_one of the same class); graft a fresh $lookup onto each path.
        chains.each do |chain|
          graft_embedded_lookup(pipeline, create_pipeline(assoc, assoc_map.dup), chain, assoc)
        end
      end

      # Handles eager loading a reference that lives on an embedded document rather
      # than on a top-level one. MongoDB's $lookup can only attach its results to a
      # top-level field, never inside an embedded array, so the matches are first
      # collected at the top level and then moved onto the embedded documents they
      # belong to, following +chain+ down to where the reference is declared.
      #
      # @param [ Array<Hash> ] pipeline The aggregation pipeline being built.
      # @param [ Hash ] stage The $lookup stage produced for +association+.
      # @param [ Array<Mongoid::Association::Relatable> ] chain The embedded
      #   ancestors from the root document down to +association+'s owner.
      # @param [ Mongoid::Association::Relatable ] association The referenced
      #   inclusion to graft onto the embedded path.
      def graft_embedded_lookup(pipeline, stage, chain, association)
        lookup = stage['$lookup']
        path = chain.map(&:store_as).join('.')
        name = association.name.to_s
        # The $lookup can't write inside an embedded array, so its matches land in
        # a temporary top-level field that graft_value distributes and then drops.
        tmp_field = "__el_#{path.tr('.', '_')}_#{name}"
        graft = {
          name: name,
          tmp: tmp_field,
          local: lookup['localField'],
          foreign: lookup['foreignField'],
          match_operator: association.is_a?(Mongoid::Association::Referenced::HasAndBelongsToMany) ? '$in' : '$eq'
        }
        lookup['localField'] = "#{path}.#{lookup['localField']}"
        lookup['as'] = tmp_field
        pipeline << stage

        root = chain.first.store_as
        pipeline << { '$set' => { root => graft_value(chain, "$#{root}", graft) } }
        pipeline << { '$unset' => tmp_field }
      end

      # Once the looked-up documents sit in a temporary top-level field, each
      # embedded document along the path has to receive the matches that are its
      # own. This expresses that hand-off. An embedded collection (embeds_many)
      # keeps a per-element result so matches don't collapse onto the first
      # element; a single embedded document (embeds_one) receives its match in place.
      #
      # @param [ Array<Mongoid::Association::Relatable> ] chain The remaining
      #   embedded ancestors to descend into.
      # @param [ String ] node The aggregation expression for the current embedded
      #   node (e.g. "$ports" or "$$port").
      # @param [ Hash ] graft The grafting parameters built by graft_embedded_lookup.
      #
      # @return [ Hash ] The aggregation expression for the enclosing $set stage.
      def graft_value(chain, node, graft)
        head, *rest = chain
        many = head.is_a?(Association::Embedded::EmbedsMany)
        element = many ? "$$#{head.store_as}" : node
        child =
          if rest.empty?
            { graft[:name] => correlated_matches(graft, element) }
          else
            next_segment = rest.first.store_as
            { next_segment => graft_value(rest, "#{element}.#{next_segment}", graft) }
          end
        merged = { '$mergeObjects' => [ element, child ] }
        many ? { '$map' => { 'input' => node, 'as' => head.store_as, 'in' => merged } } : merged
      end

      # From the pool of looked-up documents, keeps only the ones that belong to a
      # particular embedded document, by matching keys. A has_and_belongs_to_many
      # holds an array of foreign keys, so a document belongs when its key is one
      # of them ($in); every other association points at a single key ($eq).
      #
      # @param [ Hash ] graft The grafting parameters built by graft_embedded_lookup.
      # @param [ String ] element The aggregation expression for the embedded element.
      #
      # @return [ Hash ] The $filter expression.
      def correlated_matches(graft, element)
        { '$filter' => {
          'input' => "$#{graft[:tmp]}",
          'as' => 'match',
          'cond' => { graft[:match_operator] => [ "$$match.#{graft[:foreign]}", "#{element}.#{graft[:local]}" ] }
        } }
      end

      # Handles references reached through an embedded document, e.g. a Computer
      # that embeds Ports where each Port references a Device. The embedded
      # document has no collection of its own to be looked up from (it already
      # travels inside its parent), so its references are attached onto the
      # embedded path instead of getting their own top-level $lookup.
      #
      # @param [ Mongoid::Association::Relatable ] embedded_assoc The embedded inclusion.
      # @param [ Array<Hash> ] pipeline_stages The sub-pipeline being built.
      # @param [ Hash<String, Array<Mongoid::Association::Relatable>> ] mapping The
      #   inclusions grouped by inverse class name, drained as children are consumed.
      # @param [ Array<Mongoid::Association::Relatable> ] chain The embedded path
      #   accumulated so far, from the outermost embedded ancestor inward.
      def nest_embedded_inclusion(embedded_assoc, pipeline_stages, mapping, chain = [ embedded_assoc ])
        child_inclusions_of(embedded_assoc, mapping).each do |child|
          mapping[child.inverse_class_name] -= [ child ]
          if child.embedded?
            nest_embedded_inclusion(child, pipeline_stages, mapping, chain + [ child ])
          else
            stage = create_pipeline(child, mapping)
            graft_embedded_lookup(pipeline_stages, stage, chain, child)
          end
        end
      end

      # Nested inclusions (e.g. include(a: :b)) form a tree. This gives the ones
      # that hang directly under +parent+, matched by the actual parent-child link
      # rather than by class, so a sibling branch isn't pulled in when an
      # association happens to point at a superclass of the queried subclass.
      #
      # @param [ Mongoid::Association::Relatable ] parent The parent inclusion.
      # @param [ Hash<String, Array<Mongoid::Association::Relatable>> ] mapping
      #   The inclusions grouped by inverse class name.
      #
      # @return [ Array<Mongoid::Association::Relatable> ] The child inclusions.
      def child_inclusions_of(parent, mapping)
        mapping.values.flatten.select do |child|
          child.parent_inclusions.include?(parent.name)
        end
      end

      # A reference can be reached through one or more embedded documents. This
      # gives the embedded path leading down to it, one per embedded parent, since
      # the same association can be embedded in more than one place (e.g. two
      # embeds_one of the same class).
      #
      # @param [ Mongoid::Association::Relatable ] assoc The inclusion.
      # @param [ Hash<Symbol, Mongoid::Association::Relatable> ] inclusions_by_name
      #   The inclusions indexed by association name.
      #
      # @return [ Array<Array<Mongoid::Association::Relatable>> ] One chain of
      #   embedded ancestors per embedded parent, each ordered from the root inward.
      def embedded_ancestor_chains(assoc, inclusions_by_name)
        assoc.parent_inclusions.filter_map do |parent_name|
          parent = inclusions_by_name[parent_name]
          embedded_chain_up_to(parent, inclusions_by_name) if parent&.embedded?
        end
      end

      # The path of embedded documents from the root down to a given embedded
      # association, found by climbing through its embedded ancestors.
      #
      # @param [ Mongoid::Association::Relatable ] embedded_assoc The embedded
      #   inclusion to start from.
      # @param [ Hash<Symbol, Mongoid::Association::Relatable> ] inclusions_by_name
      #   The inclusions indexed by association name.
      #
      # @return [ Array<Mongoid::Association::Relatable> ] The chain of embedded
      #   ancestors, outermost first.
      def embedded_chain_up_to(embedded_assoc, inclusions_by_name)
        chain = [ embedded_assoc ]
        current = embedded_assoc
        while (ancestor = inclusions_by_name[current.parent_inclusions.first]) && ancestor.embedded?
          chain.unshift(ancestor)
          current = ancestor
        end
        chain
      end

      # Preload polymorphic belongs_to inclusions onto the already-materialized
      # root documents. The target collection differs per *_type, so this cannot
      # be a $lookup; each inclusion is resolved with a single aggregation whose
      # $facet has one branch per distinct type.
      def preload_polymorphic(inclusions, docs)
        inclusions.each do |assoc|
          keys_by_type = polymorphic_keys_by_type(assoc, docs)
          targets = fetch_polymorphic_targets(assoc, keys_by_type)
          assign_polymorphic_targets(assoc, docs, targets)
        end
      end

      # Group the foreign keys found on the documents by their polymorphic type,
      # e.g. { "Printer" => [ id1 ], "Scanner" => [ id2 ] }.
      def polymorphic_keys_by_type(assoc, docs)
        docs.each_with_object({}) do |doc, keys_by_type|
          type, key = polymorphic_reference(assoc, doc)
          (keys_by_type[type] ||= []) << key if type
        end
      end

      # Fetch every target in one aggregation: a $facet with a $lookup branch per
      # type. Returns the targets as { type => { primary_key => document } }.
      def fetch_polymorphic_targets(assoc, keys_by_type)
        return {} if keys_by_type.empty?

        primary_key = assoc.primary_key
        facets = keys_by_type.to_h do |type, keys|
          collection = assoc.resolver.model_for(type).collection.name
          [ type, polymorphic_facet_branch(collection, primary_key, keys) ]
        end

        aggregated = klass.collection.aggregate([ { '$limit' => 1 }, { '$facet' => facets } ]).first
        aggregated.to_h do |type, branch|
          model = assoc.resolver.model_for(type)
          # $limit => 1 makes each branch yield a single wrapper holding the matches.
          targets = branch.first['matches'].map { |doc| Factory.from_db(model, doc) }
          [ type, targets.index_by { |doc| doc.send(primary_key) } ]
        end
      end

      # One $facet branch: look up the documents in +collection+ whose primary key
      # is among +keys+, exposed under "matches".
      def polymorphic_facet_branch(collection, primary_key, keys)
        [
          { '$lookup' => {
            'from' => collection,
            'pipeline' => [ { '$match' => { primary_key => { '$in' => keys.uniq } } } ],
            'as' => 'matches'
          } },
          { '$project' => { '_id' => 0, 'matches' => 1 } }
        ]
      end

      # Set the eager-loaded target on each document, matched by its type and key.
      def assign_polymorphic_targets(assoc, docs, targets)
        docs.each do |doc|
          type, key = polymorphic_reference(assoc, doc)
          doc.set_relation(assoc.name, type && targets.dig(type, key))
        end
      end

      # The [ type, key ] polymorphic reference stored on the document for this
      # association, or nil when the document holds no reference.
      def polymorphic_reference(assoc, doc)
        type_field = assoc.inverse_type
        key_field = assoc.foreign_key
        return unless doc.respond_to?(type_field) && doc.respond_to?(key_field)

        type = doc.send(type_field)
        key = doc.send(key_field)
        [ type, key ] if type && key
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

      # Returns the inclusions whose target class resides in a different cluster
      # than the root class.
      #
      # @return [ Array<Mongoid::Association::Relatable> ] The offending inclusions.
      def cross_cluster_inclusions
        root_client = klass.client_name
        # Polymorphic associations have no single resolvable klass and are not
        # loaded via $lookup, so they are never cross-cluster offenders.
        criteria.inclusions.reject do |assoc|
          assoc.polymorphic? || assoc.klass.client_name == root_client
        end
      end

      public

      def switch_local_and_foreign_fields?(association)
        association.is_a?(Mongoid::Association::Referenced::BelongsTo) ||
          association.is_a?(Mongoid::Association::Referenced::HasAndBelongsToMany)
      end

      def create_pipeline(current_assoc, mapping)
        # Build nested pipeline for children and ordering
        pipeline_stages = []

        # For belongs_to and has_and_belongs_to_many, the foreign key is on the current document
        # For has_many/has_one, the foreign key is on the related document
        if switch_local_and_foreign_fields?(current_assoc)
          local_field = current_assoc.foreign_key
          foreign_field = current_assoc.primary_key
        else
          local_field = current_assoc.primary_key
          foreign_field = current_assoc.foreign_key
        end

        stage = {
          '$lookup' => {
            'from' => current_assoc.klass.collection.name,
            'localField' => local_field,
            'foreignField' => foreign_field,
            'as' => current_assoc.name.to_s
          }
        }

        # A subclass shares its collection with sibling subclasses, so restrict the
        # lookup to the target's own discriminators, like a normal query would.
        if current_assoc.klass.hereditary?
          target = current_assoc.klass
          pipeline_stages << { '$match' => { target.discriminator_key => { '$in' => target._types } } }
        end

        # Add ordering if defined on the association, or default to _id for consistent order
        if current_assoc.order
          sort_spec = current_assoc.order.is_a?(Hash) ? current_assoc.order : { current_assoc.order => 1 }
          pipeline_stages << { '$sort' => sort_spec }
        else
          # Default to sorting by _id to maintain insertion order consistency
          pipeline_stages << { '$sort' => { '_id' => 1 } }
        end

        # Nest each child inclusion, dropping it from the mapping as it is consumed
        # to prevent loops with circular references. An embedded child emits no
        # $lookup of its own (it rides inside this document); its referenced
        # children are grafted onto the embedded path by nest_embedded_inclusion.
        child_inclusions_of(current_assoc, mapping).each do |child|
          mapping[child.inverse_class_name] -= [ child ]
          if child.embedded?
            nest_embedded_inclusion(child, pipeline_stages, mapping)
          else
            pipeline_stages << create_pipeline(child, mapping)
          end
        end

        # Always add pipeline since we always have at least $sort
        stage['$lookup']['pipeline'] = pipeline_stages

        stage
      end
    end
  end
end
