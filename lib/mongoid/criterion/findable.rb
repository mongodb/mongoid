# encoding: utf-8
module Mongoid
  module Criterion
    module Findable

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
      def execute_or_raise(ids, multi)
        result = multiple_from_map_or_db(ids)
        check_for_missing_documents!(result, ids)
        multi ? result : result.first
      end

      # Find the matchind document(s) in the criteria for the provided ids.
      #
      # @example Find by an id.
      #   criteria.find(Moped::BSON::ObjectId.new)
      #
      # @example Find by multiple ids.
      #   criteria.find([ Moped::BSON::ObjectId.new, Moped::BSON::ObjectId.new ])
      #
      # @param [ Array<Moped::BSON::ObjectId> ] args The ids to search for.
      #
      # @return [ Array<Document>, Document ] The matching document(s).
      #
      # @since 1.0.0
      def find(*args)
        ids = args.__find_args__
        raise_invalid if ids.any?(&:nil?)
        for_ids(ids).execute_or_raise(ids, args.multi_arged?)
      end

      # Adds a criterion to the +Criteria+ that specifies an id that must be matched.
      #
      # @example Add a single id criteria.
      #   criteria.for_ids([ 1 ])
      #
      # @example Add multiple id criteria.
      #   criteria.for_ids([ 1, 2 ])
      #
      # @param [ Array ] ids The array of ids.
      #
      # @return [ Criteria ] The cloned criteria.
      def for_ids(ids)
        ids = mongoize_ids(ids)
        if ids.size > 1
          send(id_finder, { _id: { "$in" => ids }})
        else
          send(id_finder, { _id: ids.first })
        end
      end

      # Get the document from the identity map, and if not found hit the
      # database.
      #
      # @example Get the document from the map or criteria.
      #   criteria.from_map_or_db
      #
      # @return [ Document ] The found document.
      #
      # @since 2.2.1
      def from_map_or_db
        id = extract_id
        id = klass.fields["_id"].mongoize(id) if id
        doc = IdentityMap.get(klass, id || selector_with_type_selection)
        return nil if doc == {}
        doc && doc.matches?(selector) ? doc : first
      end

      # Get the documents from the identity map, and if not found hit the
      # database.
      #
      # @example Get the documents from the map or criteria.
      #   criteria.multiple_from_map_or_db(ids)
      #
      # @param [ ids ] The searched ids.
      #
      # @return [ Array<Document> ] The found documents.
      def multiple_from_map_or_db(ids)
        return entries if embedded?
        ids = mongoize_ids(ids)
        result = from_identity_map(ids)
        ids.empty? ? result : result + from_database(ids)
      end

      private

      # Get the finder used to generate the id query.
      #
      # @api private
      #
      # @example Get the id finder.
      #   criteria.id_finder
      #
      # @return [ Symbol ] The name of the finder method.
      #
      # @since 3.1.0
      def id_finder
        @id_finder ||= extract_id ? :all_of : :where
      end

      # Get documents from the database only.
      #
      # @api private
      #
      # @example Get documents from the database.
      #   criteria.from_database(ids)
      #
      # @param [ Array<Object> ] ids The ids to fetch with.
      #
      # @return [ Array<Document> ] The matching documents.
      #
      # @since 3.0.0
      def from_database(ids)
        (ids.size > 1 ? any_in(id: ids) : where(id: ids.first)).entries
      end

      # Get documents from the identity map only.
      #
      # @api private
      #
      # @example Get documents from the identity map.
      #   criteria.from_identity_map(ids)
      #
      # @param [ Array<Object> ] ids The ids to fetch with.
      #
      # @return [ Array<Document> ] The matching documents.
      #
      # @since 3.0.0
      def from_identity_map(ids)
        result = []
        selection = selector_with_type_selection
        ids.reject! do |id|
          doc = IdentityMap.get(klass, id)
          doc && doc.matches?(selection) ? result.push(doc) : false
        end
        result
      end

      # Convert all the ids to their proper types.
      #
      # @api private
      #
      # @example Convert the ids.
      #   criteria.mongoize_ids(ids)
      #
      # @param [ Array<Object> ] ids The ids to convert.
      #
      # @return [ Array<Object> ] The converted ids.
      #
      # @since 3.0.0
      def mongoize_ids(ids)
        ids.map{ |id| klass.fields["_id"].mongoize(id) }
      end

      # Convenience method of raising an invalid options error.
      #
      # @example Raise the error.
      #   criteria.raise_invalid
      #
      # @raise [ Errors::InvalidOptions ] The error.
      #
      # @since 2.0.0
      def raise_invalid
        raise Errors::InvalidFind.new
      end
    end
  end
end
