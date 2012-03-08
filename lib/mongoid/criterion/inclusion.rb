# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:
    module Inclusion

      # Find the matchind document(s) in the criteria for the provided ids.
      #
      # @example Find by an id.
      #   criteria.find(BSON::ObjectId.new)
      #
      # @example Find by multiple ids.
      #   criteria.find([ BSON::ObjectId.new, BSON::ObjectId.new ])
      #
      # @param [ Array<BSON::ObjectId> ] args The ids to search for.
      #
      # @return [ Array<Document>, Document ] The matching document(s).
      def find(*args)
        ids = args.flat_map{ |arg| arg.is_a?(::Range) ? arg.to_a : arg }
        raise_invalid if ids.any?(&:nil?)
        for_ids(ids).execute_or_raise(args)
      end

      # Execute the criteria or raise an error if no documents found.
      #
      # @example Execute or raise
      #   criteria.execute_or_raise(id)
      #
      # @param [ Object ] args The arguments passed.
      #
      # @raise [ Errors::DocumentNotFound ] If nothing returned.
      #
      # @return [ Document, Array<Document> ] The document(s).
      #
      # @since 2.0.0
      def execute_or_raise(args)
        ids = args[0]
        ids = ids.to_a if ids.is_a?(::Range)
        if ids.is_a?(::Array)
          entries.tap do |result|
            if (entries.size < ids.size) && Mongoid.raise_not_found_error
              missing = ids - entries.map(&:_id)
              raise Errors::DocumentNotFound.new(klass, ids, missing)
            end
          end
        else
          from_map_or_db.tap do |result|
            if result.nil? && ids && Mongoid.raise_not_found_error
              raise Errors::DocumentNotFound.new(klass, ids, ids)
            end
          end
        end
      end

      # Get the document from the identity map, and if not found hit the
      # database.
      #
      # @example Get the document from the map or criteria.
      #   criteria.from_map_or_db(criteria)
      #
      # @param [ Criteria ] The cloned criteria.
      #
      # @return [ Document ] The found document.
      #
      # @since 2.2.1
      def from_map_or_db
        doc = IdentityMap.get(klass, extract_id || selector)
        doc && doc.matches?(selector) ? doc : first
      end

      # Eager loads all the provided relations. Will load all the documents
      # into the identity map who's ids match based on the extra query for the
      # ids.
      #
      # @note This will only work if Mongoid's identity map is enabled. To do
      #   so set identity_map_enabled: true in your mongoid.yml
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
      # @param [ Array<Symbol> ] relations The names of the relations to eager
      #   load.
      #
      # @return [ Criteria ] The cloned criteria.
      #
      # @since 2.2.0
      def includes(*relations)
        inclusions.concat(relations.flatten.map do |name|
          klass.reflect_on_association(name)
        end)
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

      def inclusions=(value)
        @inclusions = value
      end
    end
  end
end
