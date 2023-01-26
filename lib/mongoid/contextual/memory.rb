# frozen_string_literal: true

require "mongoid/contextual/aggregable/memory"
require "mongoid/association/eager_loadable"

module Mongoid
  module Contextual
    class Memory
      include Enumerable
      include Aggregable::Memory
      include Association::EagerLoadable
      include Queryable
      include Positional

      # @attribute [r] root The root document.
      # @attribute [r] path The atomic path.
      # @attribute [r] selector The root document selector.
      # @attribute [r] matching The in memory documents that match the selector.
      attr_reader :documents, :path, :root, :selector

      # Check if the context is equal to the other object.
      #
      # @example Check equality.
      #   context == []
      #
      # @param [ Array ] other The other array.
      #
      # @return [ true | false ] If the objects are equal.
      def ==(other)
        return false unless other.respond_to?(:entries)
        entries == other.entries
      end

      # Delete all documents in the database that match the selector.
      #
      # @example Delete all the documents.
      #   context.delete
      #
      # @return [ nil ] Nil.
      def delete
        deleted = count
        removed = map do |doc|
          prepare_remove(doc)
          doc.send(:as_attributes)
        end
        unless removed.empty?
          collection.find(selector).update_one(
            positionally(selector, "$pullAll" => { path => removed }),
            session: _session
          )
        end
        deleted
      end
      alias :delete_all :delete

      # Destroy all documents in the database that match the selector.
      #
      # @example Destroy all the documents.
      #   context.destroy
      #
      # @return [ nil ] Nil.
      def destroy
        deleted = count
        each do |doc|
          documents.delete_one(doc)
          doc.destroy
        end
        deleted
      end
      alias :destroy_all :destroy

      # Get the distinct values in the db for the provided field.
      #
      # @example Get the distinct values.
      #   context.distinct(:name)
      #
      # @param [ String | Symbol ] field The name of the field.
      #
      # @return [ Array<Object> ] The distinct values for the field.
      def distinct(field)
        if Mongoid.legacy_pluck_distinct
          documents.map{ |doc| doc.send(field) }.uniq
        else
          pluck(field).uniq
        end
      end

      # Iterate over the context. If provided a block, yield to a Mongoid
      # document for each, otherwise return an enum.
      #
      # @example Iterate over the context.
      #   context.each do |doc|
      #     puts doc.name
      #   end
      #
      # @return [ Enumerator ] The enumerator.
      def each
        if block_given?
          documents_for_iteration.each do |doc|
            yield(doc)
          end
          self
        else
          to_enum
        end
      end

      # Do any documents exist for the context.
      #
      # @example Do any documents exist for the context.
      #   context.exists?
      #
      # @example Do any documents exist for given _id.
      #   context.exists?(BSON::ObjectId(...))
      #
      # @example Do any documents exist for given conditions.
      #   context.exists?(name: "...")
      #
      # @param [ Hash | Object | false ] id_or_conditions an _id to
      #   search for, a hash of conditions, nil or false.
      #
      # @return [ true | false ] If the count is more than zero.
      #   Always false if passed nil or false.
      def exists?(id_or_conditions = :none)
        case id_or_conditions
        when :none then any?
        when nil, false then false
        when Hash then Memory.new(criteria.where(id_or_conditions)).exists?
        else Memory.new(criteria.where(_id: id_or_conditions)).exists?
        end
      end

      # Get the first document in the database for the criteria's selector.
      #
      # @example Get the first document.
      #   context.first
      #
      # @param [ Integer ] limit The number of documents to return.
      #
      # @return [ Document ] The first document.
      def first(limit = nil)
        if limit
          eager_load(documents.first(limit))
        else
          eager_load([documents.first]).first
        end
      end
      alias :one :first
      alias :find_first :first

      # Get the first document in the database for the criteria's selector or
      # raise an error if none is found.
      #
      # @example Get the first document.
      #   context.first!
      #
      # @return [ Document ] The first document.
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] raises when there are no
      #   documents to take.
      def first!
        first || raise_document_not_found_error
      end

      # Create the new in memory context.
      #
      # @example Create the new context.
      #   Memory.new(criteria)
      #
      # @param [ Criteria ] criteria The criteria.
      def initialize(criteria)
        @criteria, @klass = criteria, criteria.klass
        @documents = criteria.documents.select do |doc|
          @root ||= doc._root
          @collection ||= root.collection
          doc._matches?(criteria.selector)
        end
        apply_sorting
        apply_options
      end

      # Increment a value on all documents.
      #
      # @example Perform the increment.
      #   context.inc(likes: 10)
      #
      # @param [ Hash ] incs The operations.
      #
      # @return [ Enumerator ] The enumerator.
      def inc(incs)
        each do |document|
          document.inc(incs)
        end
      end

      # Get the last document in the database for the criteria's selector.
      #
      # @example Get the last document.
      #   context.last
      #
      # @param [ Integer ] limit The number of documents to return.
      #
      # @return [ Document ] The last document.
      def last(limit = nil)
        if limit
          eager_load(documents.last(limit))
        else
          eager_load([documents.last]).first
        end
      end

      # Get the last document in the database for the criteria's selector or
      # raise an error if none is found.
      #
      # @example Get the last document.
      #   context.last!
      #
      # @return [ Document ] The last document.
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] raises when there are no
      #   documents to take.
      def last!
        last || raise_document_not_found_error
      end

      # Get the length of matching documents in the context.
      #
      # @example Get the length of matching documents.
      #   context.length
      #
      # @return [ Integer ] The matching length.
      def length
        documents.length
      end
      alias :size :length

      # Limits the number of documents that are returned.
      #
      # @example Limit the documents.
      #   context.limit(20)
      #
      # @param [ Integer ] value The number of documents to return.
      #
      # @return [ Memory ] The context.
      def limit(value)
        self.limiting = value
        self
      end

      # Pluck the field values in memory.
      #
      # @example Get the values in memory.
      #   context.pluck(:name)
      #
      # @param [ [ String | Symbol ]... ] *fields Field(s) to pluck.
      #
      # @return [ Array<Object> | Array<Array<Object>> ] The plucked values.
      def pluck(*fields)
        if Mongoid.legacy_pluck_distinct
          documents.pluck(*fields)
        else
          documents.map do |doc|
            pluck_from_doc(doc, *fields)
          end
        end
      end

      # Pick the field values in memory.
      #
      # @example Get the values in memory.
      #   context.pick(:name)
      #
      # @param [ [ String | Symbol ]... ] *fields Field(s) to pick.
      #
      # @return [ Object | Array<Object> ] The picked values.
      def pick(*fields)
        if doc = documents.first
          pluck_from_doc(doc, *fields)
        end
      end

      # Tally the field values in memory.
      #
      # @example Get the counts of values in memory.
      #   context.tally(:name)
      #
      # @param [ String | Symbol ] field Field to tally.
      #
      # @return [ Hash ] The hash of counts.
      def tally(field)
        return documents.each_with_object({}) do |d, acc|
          v = retrieve_value_at_path(d, field)
          acc[v] ||= 0
          acc[v] += 1
        end
      end

      # Take the given number of documents from the database.
      #
      # @example Take a document.
      #   context.take
      #
      # @param [ Integer | nil ] limit The number of documents to take or nil.
      #
      # @return [ Document ] The document.
      def take(limit = nil)
        if limit
          eager_load(documents.take(limit))
        else
          eager_load([documents.first]).first
        end
      end

      # Take the given number of documents from the database or raise an error
      # if none are found.
      #
      # @example Take a document.
      #   context.take
      #
      # @return [ Document ] The document.
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] raises when there are no
      #   documents to take.
      def take!
        take || raise_document_not_found_error
      end

      # Skips the provided number of documents.
      #
      # @example Skip the documents.
      #   context.skip(20)
      #
      # @param [ Integer ] value The number of documents to skip.
      #
      # @return [ Memory ] The context.
      def skip(value)
        self.skipping = value
        self
      end

      # Sorts the documents by the provided spec.
      #
      # @example Sort the documents.
      #   context.sort(name: -1, title: 1)
      #
      # @param [ Hash ] values The sorting values as field/direction(1/-1)
      #   pairs.
      #
      # @return [ Memory ] The context.
      def sort(values)
        in_place_sort(values) and self
      end

      # Update the first matching document atomically.
      #
      # @example Update the matching document.
      #   context.update(name: "Smiths")
      #
      # @param [ Hash ] attributes The new attributes for the document.
      #
      # @return [ nil | false ] False if no attributes were provided.
      def update(attributes = nil)
        update_documents(attributes, [ first ])
      end

      # Update all the matching documents atomically.
      #
      # @example Update all the matching documents.
      #   context.update_all(name: "Smiths")
      #
      # @param [ Hash ] attributes The new attributes for each document.
      #
      # @return [ nil | false ] False if no attributes were provided.
      def update_all(attributes = nil)
        update_documents(attributes, entries)
      end

      # Get the second document in the database for the criteria's selector.
      #
      # @example Get the second document.
      #   context.second
      #
      # @param [ Integer ] limit The number of documents to return.
      #
      # @return [ Document ] The second document.
      def second
        eager_load([documents.second]).first
      end

      # Get the second document in the database for the criteria's selector or
      # raise an error if none is found.
      #
      # @example Get the second document.
      #   context.second!
      #
      # @return [ Document ] The second document.
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] raises when there are no
      #   documents to take.
      def second!
        second || raise_document_not_found_error
      end

      # Get the third document in the database for the criteria's selector.
      #
      # @example Get the third document.
      #   context.third
      #
      # @param [ Integer ] limit The number of documents to return.
      #
      # @return [ Document ] The third document.
      def third
        eager_load([documents.third]).first
      end

      # Get the third document in the database for the criteria's selector or
      # raise an error if none is found.
      #
      # @example Get the third document.
      #   context.third!
      #
      # @return [ Document ] The third document.
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] raises when there are no
      #   documents to take.
      def third!
        third || raise_document_not_found_error
      end

      # Get the fourth document in the database for the criteria's selector.
      #
      # @example Get the fourth document.
      #   context.fourth
      #
      # @param [ Integer ] limit The number of documents to return.
      #
      # @return [ Document ] The fourth document.
      def fourth
        eager_load([documents.fourth]).first
      end

      # Get the fourth document in the database for the criteria's selector or
      # raise an error if none is found.
      #
      # @example Get the fourth document.
      #   context.fourth!
      #
      # @return [ Document ] The fourth document.
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] raises when there are no
      #   documents to take.
      def fourth!
        fourth || raise_document_not_found_error
      end

      # Get the fifth document in the database for the criteria's selector.
      #
      # @example Get the fifth document.
      #   context.fifth
      #
      # @param [ Integer ] limit The number of documents to return.
      #
      # @return [ Document ] The fifth document.
      def fifth
        eager_load([documents.fifth]).first
      end

      # Get the fifth document in the database for the criteria's selector or
      # raise an error if none is found.
      #
      # @example Get the fifth document.
      #   context.fifth!
      #
      # @return [ Document ] The fifth document.
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] raises when there are no
      #   documents to take.
      def fifth!
        fifth || raise_document_not_found_error
      end

      # Get the second to last document in the database for the criteria's selector.
      #
      # @example Get the second to last document.
      #   context.second_to_last
      #
      # @param [ Integer ] limit The number of documents to return.
      #
      # @return [ Document ] The second to last document.
      def second_to_last
        eager_load([documents.second_to_last]).first
      end

      # Get the second to last document in the database for the criteria's selector or
      # raise an error if none is found.
      #
      # @example Get the second to last document.
      #   context.second_to_last!
      #
      # @return [ Document ] The second to last document.
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] raises when there are no
      #   documents to take.
      def second_to_last!
        second_to_last || raise_document_not_found_error
      end

      # Get the third to last document in the database for the criteria's selector.
      #
      # @example Get the third to last document.
      #   context.third_to_last
      #
      # @param [ Integer ] limit The number of documents to return.
      #
      # @return [ Document ] The third to last document.
      def third_to_last
        eager_load([documents.third_to_last]).first
      end

      # Get the third to last document in the database for the criteria's selector or
      # raise an error if none is found.
      #
      # @example Get the third to last document.
      #   context.third_to_last!
      #
      # @return [ Document ] The third to last document.
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] raises when there are no
      #   documents to take.
      def third_to_last!
        third_to_last || raise_document_not_found_error
      end

      private

      # Get the documents the context should iterate. This follows 3 rules:
      #
      # @api private
      #
      # @example Get the documents for iteration.
      #   context.documents_for_iteration
      #
      # @return [ Array<Document> ] The docs to iterate.
      def documents_for_iteration
        docs = documents[skipping || 0, limiting || documents.length] || []
        if eager_loadable?
          eager_load(docs)
        end
        docs
      end

      # Update the provided documents with the attributes.
      #
      # @api private
      #
      # @example Update the documents.
      #   context.update_documents({}, doc)
      #
      # @param [ Hash ] attributes The attributes.
      # @param [ Array<Document> ] docs The docs to update.
      def update_documents(attributes, docs)
        return false if !attributes || docs.empty?
        updates = { "$set" => {}}
        docs.each do |doc|
          @selector ||= root.atomic_selector
          doc.write_attributes(attributes)
          updates["$set"].merge!(doc.atomic_updates["$set"] || {})
          doc.move_changes
        end
        collection.find(selector).update_one(updates, session: _session) unless updates["$set"].empty?
      end

      # Get the limiting value.
      #
      # @api private
      #
      # @example Get the limiting value.
      #
      # @return [ Integer ] The limit.
      def limiting
        defined?(@limiting) ? @limiting : nil
      end

      # Set the limiting value.
      #
      # @api private
      #
      # @example Set the limiting value.
      #
      # @param [ Integer ] value The limit.
      #
      # @return [ Integer ] The limit.
      def limiting=(value)
        @limiting = value
      end

      # Get the skipping value.
      #
      # @api private
      #
      # @example Get the skipping value.
      #
      # @return [ Integer ] The skip.
      def skipping
        defined?(@skipping) ? @skipping : nil
      end

      # Set the skipping value.
      #
      # @api private
      #
      # @example Set the skipping value.
      #
      # @param [ Integer ] value The skip.
      #
      # @return [ Integer ] The skip.
      def skipping=(value)
        @skipping = value
      end

      # Apply criteria options.
      #
      # @api private
      #
      # @example Apply criteria options.
      #   context.apply_options
      #
      # @return [ Memory ] self.
      def apply_options
        raise Errors::InMemoryCollationNotSupported.new if criteria.options[:collation]
        skip(criteria.options[:skip]).limit(criteria.options[:limit])
      end

      # Map the sort symbols to the correct MongoDB values.
      #
      # @example Apply the sorting params.
      #   context.apply_sorting
      def apply_sorting
        if spec = criteria.options[:sort]
          in_place_sort(spec)
        end
      end

      # Compare two values, checking for nil.
      #
      # @api private
      #
      # @example Compare the two objects.
      #   context.compare(a, b)
      #
      # @param [ Object ] a The first object.
      # @param [ Object ] b The first object.
      #
      # @return [ Integer ] The comparison value.
      def compare(a, b)
        case
        when a.nil? then b.nil? ? 0 : 1
        when b.nil? then -1
        else a <=> b
        end
      end

      # Sort the documents in place.
      #
      # @example Sort the documents.
      #   context.in_place_sort(name: 1)
      #
      # @param [ Hash ] values The field/direction sorting pairs.
      def in_place_sort(values)
        documents.sort! do |a, b|
          values.map do |field, direction|
            a_value, b_value = a[field], b[field]
            direction * compare(a_value.__sortable__, b_value.__sortable__)
          end.find { |value| !value.zero? } || 0
        end
      end

      # Prepare the document for batch removal.
      #
      # @api private
      #
      # @example Prepare for removal.
      #   context.prepare_remove(doc)
      #
      # @param [ Document ] doc The document.
      def prepare_remove(doc)
        @selector ||= root.atomic_selector
        @path ||= doc.atomic_path
        documents.delete_one(doc)
        doc._parent.remove_child(doc)
        doc.destroyed = true
      end

      private

      def _session
        @criteria.send(:_session)
      end

      # Retrieve the value for the current document at the given field path.
      #
      # For example, if I have the following models:
      #
      #   User has_many Accounts
      #   address is a hash on Account
      #
      #   u = User.new(accounts: [ Account.new(address: { street: "W 50th" }) ])
      #   retrieve_value_at_path(u, "user.accounts.address.street")
      #   # => [ "W 50th" ]
      #
      # Note that the result is in an array since accounts is an array. If it
      # was nested in two arrays the result would be in a 2D array.
      #
      # @param [ Object ] document The object to traverse the field path.
      # @param [ String ] field_path The dotted string that represents the path
      #   to the value.
      #
      # @return [ Object | nil ] The value at the given field path or nil if it
      #   doesn't exist.
      def retrieve_value_at_path(document, field_path)
        return if field_path.blank? || !document
        segment, remaining = field_path.to_s.split('.', 2)

        curr = if document.is_a?(Document)
          # Retrieves field for segment to check localization. Only does one
          # iteration since there's no dots
          res = if remaining
            field = document.class.traverse_association_tree(segment)
            # If this is a localized field, and there are remaining, get the
            # _translations hash so that we can get the specified translation in
            # the remaining
            if field&.localized?
              document.send("#{segment}_translations")
            end
          end
          meth = klass.aliased_associations[segment] || segment
          res.nil? ? document.try(meth) : res
        elsif document.is_a?(Hash)
          # TODO: Remove the indifferent access when implementing MONGOID-5410.
          document.key?(segment.to_s) ?
            document[segment.to_s] :
            document[segment.to_sym]
        else
          nil
        end

        return curr unless remaining

        if curr.is_a?(Array)
          # compact is used for consistency with server behavior.
          curr.map { |d| retrieve_value_at_path(d, remaining) }.compact
        else
          retrieve_value_at_path(curr, remaining)
        end
      end

      # Pluck the field values from the given document.
      #
      # @param [ Document ] doc The document to pluck from.
      # @param [ [ String | Symbol ]... ] *fields Field(s) to pluck.
      #
      # @return [ Object | Array<Object> ] The plucked values.
      def pluck_from_doc(doc, *fields)
        if fields.length == 1
          retrieve_value_at_path(doc, fields.first)
        else
          fields.map do |field|
            retrieve_value_at_path(doc, field)
          end
        end
      end

      def raise_document_not_found_error
        raise Errors::DocumentNotFound.new(klass, nil, nil)
      end
    end
  end
end
