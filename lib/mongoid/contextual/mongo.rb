# frozen_string_literal: true

require "mongoid/contextual/mongo/documents_loader"
require "mongoid/contextual/atomic"
require "mongoid/contextual/aggregable/mongo"
require "mongoid/contextual/command"
require "mongoid/contextual/geo_near"
require "mongoid/contextual/map_reduce"
require "mongoid/association/eager_loadable"

module Mongoid
  module Contextual
    class Mongo
      extend Forwardable
      include Enumerable
      include Aggregable::Mongo
      include Atomic
      include Association::EagerLoadable
      include Queryable

      Mongoid.deprecate(self, :geo_near)

      # Options constant.
      OPTIONS = [ :hint,
                  :limit,
                  :skip,
                  :sort,
                  :batch_size,
                  :max_scan,
                  :max_time_ms,
                  :snapshot,
                  :comment,
                  :read,
                  :cursor_type,
                  :collation
                ].freeze

      # @attribute [r] view The Mongo collection view.
      attr_reader :view

      # Run an explain on the criteria.
      #
      # @example Explain the criteria.
      #   Band.where(name: "Depeche Mode").explain
      #
      # @param [ Hash ] options customizable options (See Mongo::Collection::View::Explainable)
      #
      # @return [ Hash ] The explain result.
      def_delegator :view, :explain

      attr_reader :documents_loader

      # Get the number of documents matching the query.
      #
      # @example Get the number of matching documents.
      #   context.count
      #
      # @example Get the count of documents with the provided options.
      #   context.count(limit: 1)
      #
      # @example Get the count for where the provided block is true.
      #   context.count do |doc|
      #     doc.likes > 1
      #   end
      #
      # @param [ Hash ] options The options, such as skip and limit to be factored
      #   into the count.
      #
      # @return [ Integer ] The number of matches.
      def count(options = {}, &block)
        return super(&block) if block_given?
        view.count_documents(options)
      end

      # Get the estimated number of documents matching the query.
      #
      # Unlike count, estimated_count does not take a block because it is not
      # traditionally defined (with a block) on Enumarable like count is.
      #
      # @example Get the estimated number of matching documents.
      #   context.estimated_count
      #
      # @param [ Hash ] options The options, such as maxTimeMS to be factored
      #   into the count.
      #
      # @return [ Integer ] The number of matches.
      def estimated_count(options = {})
        unless self.criteria.selector.empty?
          raise Mongoid::Errors::InvalidEstimatedCountCriteria.new(self.klass)
        end
        view.estimated_document_count(options)
      end

      # Delete all documents in the database that match the selector.
      #
      # @example Delete all the documents.
      #   context.delete
      #
      # @return [ nil ] Nil.
      def delete
        view.delete_many.deleted_count
      end
      alias :delete_all :delete

      # Destroy all documents in the database that match the selector.
      #
      # @example Destroy all the documents.
      #   context.destroy
      #
      # @return [ nil ] Nil.
      def destroy
        each.inject(0) do |count, doc|
          doc.destroy
          count += 1 if acknowledged_write?
          count
        end
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
        name = if Mongoid.legacy_pluck_distinct
          klass.database_field_name(field)
        else
          klass.cleanse_localized_field_names(field)
        end

        view.distinct(name).map do |value|
          if Mongoid.legacy_pluck_distinct
            value.class.demongoize(value)
          else
            is_translation = "#{name}_translations" == field.to_s
            recursive_demongoize(name, value, is_translation)
          end
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
      def each(&block)
        if block_given?
          documents_for_iteration.each do |doc|
            yield_document(doc, &block)
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
      # @note We don't use count here since Mongo does not use counted
      #   b-tree indexes.
      #
      # @param [ Hash | Object | false ] id_or_conditions an _id to
      #   search for, a hash of conditions, nil or false.
      #
      # @return [ true | false ] If the count is more than zero.
      #   Always false if passed nil or false.
      def exists?(id_or_conditions = :none)
        return false if self.view.limit == 0
        case id_or_conditions
        when :none then !!(view.projection(_id: 1).limit(1).first)
        when nil, false then false
        when Hash then Mongo.new(criteria.where(id_or_conditions)).exists?
        else Mongo.new(criteria.where(_id: id_or_conditions)).exists?
        end
      end

      # Execute the find and modify command, used for MongoDB's
      # $findAndModify.
      #
      # @example Execute the command.
      #   context.find_one_and_update({ "$inc" => { likes: 1 }})
      #
      # @param [ Hash ] update The updates.
      # @param [ Hash ] options The command options.
      #
      # @option options [ :before | :after ] :return_document Return the updated document
      #   from before or after update.
      # @option options [ true | false ] :upsert Create the document if it doesn't exist.
      #
      # @return [ Document ] The result of the command.
      def find_one_and_update(update, options = {})
        if doc = view.find_one_and_update(update, options)
          Factory.from_db(klass, doc)
        end
      end

      # Execute the find and modify command, used for MongoDB's
      # $findAndModify.
      #
      # @example Execute the command.
      #   context.find_one_and_update({ likes: 1 })
      #
      # @param [ Hash ] replacement The replacement.
      # @param [ Hash ] options The command options.
      #
      # @option options [ :before | :after ] :return_document Return the updated document
      #   from before or after update.
      # @option options [ true | false ] :upsert Create the document if it doesn't exist.
      #
      # @return [ Document ] The result of the command.
      def find_one_and_replace(replacement, options = {})
        if doc = view.find_one_and_replace(replacement, options)
          Factory.from_db(klass, doc)
        end
      end

      # Execute the find and modify command, used for MongoDB's
      # $findAndModify. This deletes the found document.
      #
      # @example Execute the command.
      #   context.find_one_and_delete
      #
      # @return [ Document ] The result of the command.
      def find_one_and_delete
        if doc = view.find_one_and_delete
          Factory.from_db(klass, doc)
        end
      end

      # Return the first result without applying sort
      #
      # @api private
      def find_first
        if raw_doc = view.first
          doc = Factory.from_db(klass, raw_doc, criteria)
          eager_load([doc]).first
        end
      end

      # Execute a $geoNear command against the database.
      #
      # @example Find documents close to 10, 10.
      #   context.geo_near([ 10, 10 ])
      #
      # @example Find with spherical distance.
      #   context.geo_near([ 10, 10 ]).spherical
      #
      # @example Find with a max distance.
      #   context.geo_near([ 10, 10 ]).max_distance(0.5)
      #
      # @example Provide a distance multiplier.
      #   context.geo_near([ 10, 10 ]).distance_multiplier(1133)
      #
      # @param [ Array<Float> ] coordinates The coordinates.
      #
      # @return [ GeoNear ] The GeoNear command.
      #
      # @deprecated
      def geo_near(coordinates)
        GeoNear.new(collection, criteria, coordinates)
      end

      # Create the new Mongo context. This delegates operations to the
      # underlying driver.
      #
      # @example Create the new context.
      #   Mongo.new(criteria)
      #
      # @param [ Criteria ] criteria The criteria.
      def initialize(criteria)
        @criteria, @klass = criteria, criteria.klass
        @collection = @klass.collection
        criteria.send(:merge_type_selection)
        @view = collection.find(criteria.selector, session: _session)
        apply_options
      end

      def_delegator :@klass, :database_field_name

      # Returns the number of documents in the database matching
      # the query selector.
      #
      # @example Get the length.
      #   context.length
      #
      # @return [ Integer ] The number of documents.
      def length
        self.count
      end
      alias :size :length

      # Limits the number of documents that are returned from the database.
      #
      # @example Limit the documents.
      #   context.limit(20)
      #
      # @param [ Integer ] value The number of documents to return.
      #
      # @return [ Mongo ] The context.
      def limit(value)
        @view = view.limit(value) and self
      end

      # Initiate a map/reduce operation from the context.
      #
      # @example Initiate a map/reduce.
      #   context.map_reduce(map, reduce)
      #
      # @param [ String ] map The map js function.
      # @param [ String ] reduce The reduce js function.
      #
      # @return [ MapReduce ] The map/reduce lazy wrapper.
      def map_reduce(map, reduce)
        MapReduce.new(collection, criteria, map, reduce)
      end

      # Pluck the field value(s) from the database. Returns one
      # result for each document found in the database for
      # the context. The results are normalized according to their
      # Mongoid field types. Note that the results may include
      # duplicates and nil values.
      #
      # @example Pluck a field.
      #   context.pluck(:_id)
      #
      # @param [ [ String | Symbol ]... ] *fields Field(s) to pluck,
      #   which may include nested fields using dot-notation.
      #
      # @return [ Array<Object> | Array<Array<Object>> ] The plucked values.
      #   If the *fields arg contains a single value, each result
      #   in the array will be a single value. Otherwise, each
      #   result in the array will be an array of values.
      def pluck(*fields)
        # Multiple fields can map to the same field name. For example, plucking
        # a field and its _translations field map to the same field in the database.
        # because of this, we need to keep track of the fields requested.
        normalized_field_names = []
        normalized_select = fields.inject({}) do |hash, f|
          db_fn = klass.database_field_name(f)
          normalized_field_names.push(db_fn)

          if Mongoid.legacy_pluck_distinct
            hash[db_fn] = true
          else
            hash[klass.cleanse_localized_field_names(f)] = true
          end
          hash
        end

        view.projection(normalized_select).reduce([]) do |plucked, doc|
          values = normalized_field_names.map do |n|
            if Mongoid.legacy_pluck_distinct
              n.include?('.') ? doc[n.partition('.')[0]] : doc[n]
            else
              extract_value(doc, n)
            end
          end
          plucked << (values.size == 1 ? values.first : values)
        end
      end

      # Pick the single field values from the database.
      #
      # @example Pick a field.
      #   context.pick(:_id)
      #
      # @param [ [ String | Symbol ]... ] *fields Field(s) to pick.
      #
      # @return [ Object | Array<Object> ] The picked values.
      def pick(*fields)
        limit(1).pluck(*fields).first
      end

      # Take the given number of documents from the database.
      #
      # @example Take 10 documents
      #   context.take(10)
      #
      # @param [ Integer | nil ] limit The number of documents to return or nil.
      #
      # @return [ Document | Array<Document> ] The list of documents, or one
      #   document if no value was given.
      def take(limit = nil)
        if limit
          limit(limit).to_a
        else
          # Do to_a first so that the Mongo#first method is not used and the
          # result is not sorted.
          limit(1).to_a.first
        end
      end

      # Take one document from the database and raise an error if there are none.
      #
      # @example Take a document
      #   context.take!
      #
      # @return [ Document ] The document.
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] raises when there are no
      #   documents to take.
      def take!
        # Do to_a first so that the Mongo#first method is not used and the
        # result is not sorted.
        if fst = limit(1).to_a.first
          fst
        else
          raise Errors::DocumentNotFound.new(klass, nil, nil)
        end
      end

      # Get a hash of counts for the values of a single field. For example,
      # if the following documents were in the database:
      #
      #   { _id: 1, age: 21 }
      #   { _id: 2, age: 21 }
      #   { _id: 3, age: 22 }
      #
      #   Model.tally("age")
      #
      # would yield the following result:
      #
      #   { 21 => 2, 22 => 1 }
      #
      # When tallying a field inside an array or embeds_many association:
      #
      #   { _id: 1, array: [ { x: 1 }, { x: 2 } ] }
      #   { _id: 2, array: [ { x: 1 }, { x: 2 } ] }
      #   { _id: 3, array: [ { x: 1 }, { x: 3 } ] }
      #
      #   Model.tally("array.x")
      #
      # The keys of the resulting hash are arrays:
      #
      #   { [ 1, 2 ] => 2, [ 1, 3 ] => 1 }
      #
      # Note that if tallying an element in an array of hashes, and the key
      # doesn't exist in some of the hashes, tally will not include those
      # nil keys in the resulting hash:
      #
      #   { _id: 1, array: [ { x: 1 }, { x: 2 }, { y: 3 } ] }
      #
      #   Model.tally("array.x")
      #   # => { [ 1, 2 ] => 1 }
      #
      # @param [ String | Symbol ] field The field name.
      #
      # @return [ Hash ] The hash of counts.
      def tally(field)
        name = klass.cleanse_localized_field_names(field)

        fld = klass.traverse_association_tree(name)
        pipeline = [ { "$group" => { _id: "$#{name}", counts: { "$sum": 1 } } } ]
        pipeline.unshift("$match" => view.filter) unless view.filter.blank?

        collection.aggregate(pipeline).reduce({}) do |tallies, doc|
          is_translation = "#{name}_translations" == field.to_s
          val = doc["_id"]

          key = if val.is_a?(Array)
            val.map do |v|
              demongoize_with_field(fld, v, is_translation)
            end
          else
            demongoize_with_field(fld, val, is_translation)
          end

          # The only time where a key will already exist in the tallies hash
          # is when the values are stored differently in the database, but
          # demongoize to the same value. A good example of when this happens
          # is when using localized fields. While the server query won't group
          # together hashes that have other values in different languages, the
          # demongoized value is just the translation in the current locale,
          # which can be the same across multiple of those unequal hashes.
          tallies[key] ||= 0
          tallies[key] += doc["counts"]
          tallies
        end
      end

      # Skips the provided number of documents.
      #
      # @example Skip the documents.
      #   context.skip(20)
      #
      # @param [ Integer ] value The number of documents to skip.
      #
      # @return [ Mongo ] The context.
      def skip(value)
        @view = view.skip(value) and self
      end

      # Sorts the documents by the provided spec.
      #
      # @example Sort the documents.
      #   context.sort(name: -1, title: 1)
      #
      # @param [ Hash ] values The sorting values as field/direction(1/-1)
      #   pairs.
      #
      # @return [ Mongo ] The context.
      def sort(values = nil, &block)
        if block_given?
          super(&block)
        else
          # update the criteria
          @criteria = criteria.order_by(values)
          apply_option(:sort)
          self
        end
      end

      # Update the first matching document atomically.
      #
      # @example Update the first matching document.
      #   context.update({ "$set" => { name: "Smiths" }})
      #
      # @param [ Hash ] attributes The new attributes for the document.
      # @param [ Hash ] opts The update operation options.
      #
      # @option opts [ Array ] :array_filters A set of filters specifying to which array elements
      #   an update should apply.
      #
      # @return [ nil | false ] False if no attributes were provided.
      def update(attributes = nil, opts = {})
        update_documents(attributes, :update_one, opts)
      end

      # Update all the matching documents atomically.
      #
      # @example Update all the matching documents.
      #   context.update_all({ "$set" => { name: "Smiths" }})
      #
      # @param [ Hash ] attributes The new attributes for each document.
      # @param [ Hash ] opts The update operation options.
      #
      # @option opts [ Array ] :array_filters A set of filters specifying to which array elements
      #   an update should apply.
      #
      # @return [ nil | false ] False if no attributes were provided.
      def update_all(attributes = nil, opts = {})
        update_documents(attributes, :update_many, opts)
      end

      # Get the first document in the database for the criteria's selector.
      #
      # @example Get the first document.
      #   context.first
      #
      # @note Automatically adding a sort on _id when no other sort is
      #   defined on the criteria has the potential to cause bad performance issues.
      #   If you experience unexpected poor performance when using #first or #last
      #   and have no sort defined on the criteria, use #take instead.
      #   Be aware that #take won't guarantee order.
      #
      # @param [ Integer ] limit The number of documents to return.
      #
      # @return [ Document | nil ] The first document or nil if none is found.
      def first(limit = nil)
        if limit.nil?
          retrieve_nth(0)
        else
          retrieve_nth_with_limit(0, limit)
        end
      end
      alias :one :first

      # Get the first document in the database for the criteria's selector or
      # raise an error if none is found.
      #
      # @example Get the first document.
      #   context.first!
      #
      # @note Automatically adding a sort on _id when no other sort is
      #   defined on the criteria has the potential to cause bad performance issues.
      #   If you experience unexpected poor performance when using #first! or #last!
      #   and have no sort defined on the criteria, use #take! instead.
      #   Be aware that #take! won't guarantee order.
      #
      # @return [ Document ] The first document.
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] raises when there are no
      #   documents available.
      def first!
        first || raise_document_not_found_error
      end

      # Get the last document in the database for the criteria's selector.
      #
      # @example Get the last document.
      #   context.last
      #
      # @note Automatically adding a sort on _id when no other sort is
      #   defined on the criteria has the potential to cause bad performance issues.
      #   If you experience unexpected poor performance when using #first or #last
      #   and have no sort defined on the criteria, use #take instead.
      #   Be aware that #take won't guarantee order.
      #
      # @param [ Integer ] limit The number of documents to return.
      #
      # @return [ Document | nil ] The last document or nil if none is found.
      def last(limit = nil)
        if limit.nil?
          retrieve_nth_to_last(0)
        else
          retrieve_nth_to_last_with_limit(0, limit)
        end
      end

      # Get the last document in the database for the criteria's selector or
      # raise an error if none is found.
      #
      # @example Get the last document.
      #   context.last!
      #
      # @note Automatically adding a sort on _id when no other sort is
      #   defined on the criteria has the potential to cause bad performance issues.
      #   If you experience unexpected poor performance when using #first! or #last!
      #   and have no sort defined on the criteria, use #take! instead.
      #   Be aware that #take! won't guarantee order.
      #
      # @return [ Document ] The last document.
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] raises when there are no
      #   documents available.
      def last!
        last || raise_document_not_found_error
      end

      # Get the second document in the database for the criteria's selector.
      #
      # @example Get the second document.
      #   context.second
      #
      # @return [ Document | nil ] The second document or nil if none is found.
      def second
        retrieve_nth(1)
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
      #   documents available.
      def second!
        second || raise_document_not_found_error
      end

      # Get the third document in the database for the criteria's selector.
      #
      # @example Get the third document.
      #   context.third
      #
      # @return [ Document | nil ] The third document or nil if none is found.
      def third
        retrieve_nth(2)
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
      #   documents available.
      def third!
        third || raise_document_not_found_error
      end

      # Get the fourth document in the database for the criteria's selector.
      #
      # @example Get the fourth document.
      #   context.fourth
      #
      # @return [ Document | nil ] The fourth document or nil if none is found.
      def fourth
        retrieve_nth(3)
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
      #   documents available.
      def fourth!
        fourth || raise_document_not_found_error
      end

      # Get the fifth document in the database for the criteria's selector.
      #
      # @example Get the fifth document.
      #   context.fifth
      #
      # @return [ Document | nil ] The fifth document or nil if none is found.
      def fifth
        retrieve_nth(4)
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
      #   documents available.
      def fifth!
        fifth || raise_document_not_found_error
      end

      # Get the second to last document in the database for the criteria's
      # selector.
      #
      # @example Get the second to last document.
      #   context.second_to_last
      #
      # @return [ Document | nil ] The second to last document or nil if none
      # is found.
      def second_to_last
        retrieve_nth_to_last(1)
      end

      # Get the second to last document in the database for the criteria's
      # selector or raise an error if none is found.
      #
      # @example Get the second to last document.
      #   context.second_to_last!
      #
      # @return [ Document ] The second to last document.
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] raises when there are no
      #   documents available.
      def second_to_last!
        second_to_last || raise_document_not_found_error
      end

      # Get the third to last document in the database for the criteria's
      # selector.
      #
      # @example Get the third to last document.
      #   context.third_to_last
      #
      # @return [ Document | nil ] The third to last document or nil if none
      # is found.
      def third_to_last
        retrieve_nth_to_last(2)
      end

      # Get the third to last document in the database for the criteria's
      # selector or raise an error if none is found.
      #
      # @example Get the third to last document.
      #   context.third_to_last!
      #
      # @return [ Document ] The third to last document.
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] raises when there are no
      #   documents available.
      def third_to_last!
        third_to_last || raise_document_not_found_error
      end

      # Schedule a task to load documents for the context.
      #
      # Depending on the Mongoid configuration, the scheduled task can be executed
      # immediately on the caller's thread, or can be scheduled for an
      # asynchronous execution.
      #
      # @api private
      def load_async
        @documents_loader ||= DocumentsLoader.new(view, klass, criteria)
      end

      private

      # Update the documents for the provided method.
      #
      # @api private
      #
      # @example Update the documents.
      #   context.update_documents(attrs)
      #
      # @param [ Hash ] attributes The updates.
      # @param [ Symbol ] method The method to use.
      #
      # @return [ true | false ] If the update succeeded.
      def update_documents(attributes, method = :update_one, opts = {})
        return false unless attributes
        attributes = Hash[attributes.map { |k, v| [klass.database_field_name(k.to_s), v] }]
        view.send(method, attributes.__consolidate__(klass), opts)
      end

      # Apply the field limitations.
      #
      # @api private
      #
      # @example Apply the field limitations.
      #   context.apply_fields
      def apply_fields
        if spec = criteria.options[:fields]
          @view = view.projection(spec)
        end
      end

      # Apply the options.
      #
      # @api private
      #
      # @example Apply all options.
      #   context.apply_options
      def apply_options
        apply_fields
        OPTIONS.each do |name|
          apply_option(name)
        end
        if criteria.options[:timeout] == false
          @view = view.no_cursor_timeout
        end
      end

      # Apply an option.
      #
      # @api private
      #
      # @example Apply the skip option.
      #   context.apply_option(:skip)
      def apply_option(name)
        if spec = criteria.options[name]
          @view = view.send(name, spec)
        end
      end

      # Map the inverse sort symbols to the correct MongoDB values.
      #
      # @api private
      def inverse_sorting
        sort = view.sort || { _id: 1 }
        Hash[sort.map{|k, v| [k, -1*v]}]
      end

      # Get the documents the context should iterate.
      #
      # If the documents have been already preloaded by `Document::Loader`
      # instance, they will be used.
      #
      # @return [ Array<Document> | Mongo::Collection::View ] The docs to iterate.
      #
      # @api private
      def documents_for_iteration
        if @documents_loader
          if @documents_loader.started?
            @documents_loader.value!
          else
            @documents_loader.unschedule
            @documents_loader.execute
          end
        else
          return view unless eager_loadable?
          docs = view.map do |doc|
            Factory.from_db(klass, doc, criteria)
          end
          eager_load(docs)
        end
      end

      # Yield to the document.
      #
      # @api private
      #
      # @example Yield the document.
      #   context.yield_document(doc) do |doc|
      #     ...
      #   end
      #
      # @param [ Document ] document The document to yield to.
      def yield_document(document, &block)
        doc = document.respond_to?(:_id) ?
            document : Factory.from_db(klass, document, criteria)
        yield(doc)
      end

      def _session
        @criteria.send(:_session)
      end

      def acknowledged_write?
        collection.write_concern.nil? || collection.write_concern.acknowledged?
      end

      # Fetch the element from the given hash and demongoize it using the
      # given field. If the obj is an array, map over it and call this method
      # on all of its elements.
      #
      # @param [ Hash | Array<Hash> ] obj The hash or array of hashes to fetch from.
      # @param [ String ] meth The key to fetch from the hash.
      # @param [ Field ] field The field to use for demongoization.
      #
      # @return [ Object ] The demongoized value.
      #
      # @api private
      def fetch_and_demongoize(obj, meth, field)
        if obj.is_a?(Array)
          obj.map { |doc| fetch_and_demongoize(doc, meth, field) }
        else
          res = obj.try(:fetch, meth, nil)
          field ? field.demongoize(res) : res.class.demongoize(res)
        end
      end

      # Extracts the value for the given field name from the given attribute
      # hash.
      #
      # @param [ Hash ] attrs The attributes hash.
      # @param [ String ] field_name The name of the field to extract.
      #
      # @param [ Object ] The value for the given field name
      def extract_value(attrs, field_name)
        i = 1
        num_meths = field_name.count('.') + 1
        curr = attrs.dup

        klass.traverse_association_tree(field_name) do |meth, obj, is_field|
          field = obj if is_field
          is_translation = false
          # If no association or field was found, check if the meth is an
          # _translations field.
          if obj.nil? & tr = meth.match(/(.*)_translations\z/)&.captures&.first
            is_translation = true
            meth = tr
          end

          # 1. If curr is an array fetch from all elements in the array.
          # 2. If the field is localized, and is not an _translations field
          #    (_translations fields don't show up in the fields hash).
          #    - If this is the end of the methods, return the translation for
          #      the current locale.
          #    - Otherwise, return the whole translations hash so the next method
          #      can select the language it wants.
          # 3. If the meth is an _translations field, do not demongoize the
          #    value so the full hash is returned.
          # 4. Otherwise, fetch and demongoize the value for the key meth.
          curr = if curr.is_a? Array
            res = fetch_and_demongoize(curr, meth, field)
            res.empty? ? nil : res
          elsif !is_translation && field&.localized?
            if i < num_meths
              curr.try(:fetch, meth, nil)
            else
              fetch_and_demongoize(curr, meth, field)
            end
          elsif is_translation
            curr.try(:fetch, meth, nil)
          else
            fetch_and_demongoize(curr, meth, field)
          end

          i += 1
        end
        curr
      end

      # Recursively demongoize the given value. This method recursively traverses
      # the class tree to find the correct field to use to demongoize the value.
      #
      # @param [ String ] field_name The name of the field to demongoize.
      # @param [ Object ] value The value to demongoize.
      # @param [ true | false ] is_translation The field we are retrieving is an
      #   _translations field.
      #
      # @return [ Object ] The demongoized value.
      def recursive_demongoize(field_name, value, is_translation)
        field = klass.traverse_association_tree(field_name)
        demongoize_with_field(field, value, is_translation)
      end

      # Demongoize the value for the given field. If the field is nil or the
      # field is a translations field, the value is demongoized using its class.
      #
      # @param [ Field ] field The field to use to demongoize.
      # @param [ Object ] value The value to demongoize.
      # @param [ true | false ] is_translation The field we are retrieving is an
      #   _translations field.
      #
      # @return [ Object ] The demongoized value.
      #
      # @api private
      def demongoize_with_field(field, value, is_translation)
        if field
          # If it's a localized field that's not a hash, don't demongoize
          # again, we already have the translation. If it's an _translations
          # field, don't demongoize, we want the full hash not just a
          # specific translation.
          # If it is a hash, and it's not a translations field, we need to
          # demongoize to get the correct translation.
          if field.localized? && (!value.is_a?(Hash) || is_translation)
            value.class.demongoize(value)
          else
            field.demongoize(value)
          end
        else
          value.class.demongoize(value)
        end
      end

      # Process the raw documents retrieved for #first/#last.
      #
      # @return [ Array<Document> | Document ] The list of documents or a
      #   single document.
      def process_raw_docs(raw_docs, limit)
        docs = raw_docs.map do |d|
          Factory.from_db(klass, d, criteria)
        end
        docs = eager_load(docs)
        limit ? docs : docs.first
      end

      def raise_document_not_found_error
        raise Errors::DocumentNotFound.new(klass, nil, nil)
      end

      def retrieve_nth(n)
        retrieve_nth_with_limit(n, 1).first
      end

      def retrieve_nth_with_limit(n, limit)
        sort = view.sort || { _id: 1 }
        v = view.sort(sort).limit(limit || 1)
        v = v.skip(n) if n > 0
        if raw_docs = v.to_a
          process_raw_docs(raw_docs, limit)
        end
      end

      def retrieve_nth_to_last(n)
        retrieve_nth_to_last_with_limit(n, 1).first
      end

      def retrieve_nth_to_last_with_limit(n, limit)
        v = view.sort(inverse_sorting).skip(n).limit(limit || 1)
        v = v.skip(n) if n > 0
        raw_docs = v.to_a.reverse
        process_raw_docs(raw_docs, limit)
      end
    end
  end
end
