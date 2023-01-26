# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      class HasMany

        # This class is the wrapper for all referenced associations that have a
        # target that can be a criteria or array of _loaded documents. This
        # handles both cases or a combination of the two.
        class Enumerable
          extend Forwardable
          include ::Enumerable

          # The three main instance variables are collections of documents.
          #
          # @attribute [rw] _added Documents that have been appended.
          # @attribute [rw] _loaded Persisted documents that have been _loaded.
          # @attribute [rw] _unloaded A criteria representing persisted docs.
          attr_accessor :_added, :_loaded, :_unloaded

          def_delegators [], :is_a?, :kind_of?

          # Check if the enumerable is equal to the other object.
          #
          # @example Check equality.
          #   enumerable == []
          #
          # @param [ Enumerable ] other The other enumerable.
          #
          # @return [ true | false ] If the objects are equal.
          def ==(other)
            return false unless other.respond_to?(:entries)
            entries == other.entries
          end

          # Check equality of the enumerable against the provided object for
          # case statements.
          #
          # @example Check case equality.
          #   enumerable === Array
          #
          # @param [ Object ] other The object to check.
          #
          # @return [ true | false ] If the objects are equal in a case.
          def ===(other)
            return false unless other.respond_to?(:entries)
            if Mongoid.legacy_triple_equals
              other.class == Class ? (Array == other || Enumerable == other) : self == other
            else
              entries === other.entries
            end
          end

          # Append a document to the enumerable.
          #
          # @example Append the document.
          #   enumerable << document
          #
          # @param [ Document ] document The document to append.
          #
          # @return [ Document ] The document.
          def <<(document)
            _added[document._id] = document
            self
          end

          alias :push :<<

          # Clears out all the documents in this enumerable. If passed a block it
          # will yield to each document that is in memory.
          #
          # @example Clear out the enumerable.
          #   enumerable.clear
          #
          # @example Clear out the enumerable with a block.
          #   enumerable.clear do |doc|
          #     doc.unbind
          #   end
          #
          # @return [ Array<Document> ] The cleared out _added docs.
          def clear
            if block_given?
              in_memory { |doc| yield(doc) }
            end
            _loaded.clear and _added.clear
          end

          # Clones each document in the enumerable.
          #
          # @note This loads all documents into memory.
          #
          # @example Clone the enumerable.
          #   enumerable.clone
          #
          # @return [ Array<Document> ] An array clone of the enumerable.
          def clone
            collect { |doc| doc.clone }
          end

          # Delete the supplied document from the enumerable.
          #
          # @example Delete the document.
          #   enumerable.delete(document)
          #
          # @param [ Document ] document The document to delete.
          #
          # @return [ Document ] The deleted document.
          def delete(document)
            doc = (_loaded.delete(document._id) || _added.delete(document._id))
            unless doc
              if _unloaded && _unloaded.where(_id: document._id).exists?
                yield(document) if block_given?
                return document
              end
            end
            yield(doc) if block_given?
            doc
          end

          # Deletes every document in the enumerable for where the block returns
          # true.
          #
          # @note This operation loads all documents from the database.
          #
          # @example Delete all matching documents.
          #   enumerable.delete_if do |doc|
          #     dod._id == _id
          #   end
          #
          # @return [ Array<Document> ] The remaining docs.
          def delete_if(&block)
            load_all!
            deleted = in_memory.select(&block)
            deleted.each do |doc|
              _loaded.delete(doc._id)
              _added.delete(doc._id)
            end
            self
          end

          # Iterating over this enumerable has to handle a few different
          # scenarios.
          #
          # If the enumerable has its criteria _loaded into memory then it yields
          # to all the _loaded docs and all the _added docs.
          #
          # If the enumerable has not _loaded the criteria then it iterates over
          # the cursor while loading the documents and then iterates over the
          # _added docs.
          #
          # If no block is passed then it returns an enumerator containing all
          # docs.
          #
          # @example Iterate over the enumerable.
          #   enumerable.each do |doc|
          #     puts doc
          #   end
          #
          # @example return an enumerator containing all the docs
          #
          #   a = enumerable.each
          #
          # @return [ true ] That the enumerable is now _loaded.
          def each
            unless block_given?
              return to_enum
            end
            if _loaded?
              _loaded.each_pair do |id, doc|
                document = _added.delete(doc._id) || doc
                set_base(document)
                yield(document)
              end
            else
              unloaded_documents.each do |doc|
                document = _added.delete(doc._id) || _loaded.delete(doc._id) || doc
                _loaded[document._id] = document
                set_base(document)
                yield(document)
              end
            end
            _added.each_pair do |id, doc|
              yield(doc)
            end
            @executed = true
          end

          # Is the enumerable empty? Will determine if the count is zero based on
          # whether or not it is _loaded.
          #
          # @example Is the enumerable empty?
          #   enumerable.empty?
          #
          # @return [ true | false ] If the enumerable is empty.
          def empty?
            if _loaded?
              in_memory.empty?
            else
              _added.empty? && !_unloaded.exists?
            end
          end

          # Returns whether the association has any documents, optionally
          # subject to the provided filters.
          #
          # This method returns true if the association has any persisted
          # documents and if it has any not yet persisted documents.
          #
          # If the association is already loaded, this method inspects the
          # loaded documents and does not query the database. If the
          # association is not loaded, the argument-less and block-less
          # version does not load the association; the other versions
          # (that delegate to Enumerable) may or may not load the association
          # completely depending on whether it is iterated to completion.
          #
          # This method can take a parameter and a block. The behavior with
          # either the parameter or the block is delegated to the standard
          # library Enumerable module.
          #
          # Note that when Enumerable's any? method is invoked with both
          # a block and a pattern, it only uses the pattern.
          #
          # @param [ Object... ] *args The condition that documents
          #   must satisfy. See Enumerable documentation for details.
          #
          # @return [ true | false ] If the association has any documents.
          def any?(*args)
            return super if args.any? || block_given?

            !empty?
          end

          # Get the first document in the enumerable. Will check the persisted
          # documents first. Does not load the entire enumerable.
          #
          # @example Get the first document.
          #   enumerable.first
          #
          # @note Automatically adding a sort on _id when no other sort is
          #   defined on the criteria has the potential to cause bad performance issues.
          #   If you experience unexpected poor performance when using #first or #last,
          #   use #take instead.
          #   Be aware that #take won't guarantee order.
          #
          # @param [ Integer ] limit The number of documents to return.
          #
          # @return [ Document ] The first document found.
          def first(limit = nil)
            _loaded.try(:values).try(:first) ||
                _added[(ul = _unloaded.try(:first, limit)).try(:_id)] ||
                ul ||
                _added.values.try(:first)
          end

          # Initialize the new enumerable either with a criteria or an array.
          #
          # @example Initialize the enumerable with a criteria.
          #   Enumberable.new(Post.where(:person_id => id))
          #
          # @example Initialize the enumerable with an array.
          #   Enumerable.new([ post ])
          #
          # @param [ Criteria | Array<Document> ] target The wrapped object.
          def initialize(target, base = nil, association = nil)
            @_base = base
            @_association = association
            if target.is_a?(Criteria)
              @_added, @executed, @_loaded, @_unloaded = {}, false, {}, target
            else
              @_added, @executed = {}, true
              @_loaded = target.inject({}) do |_target, doc|
                _target[doc._id] = doc if doc
                _target
              end
            end
          end

          # Does the target include the provided document?
          #
          # @example Does the target include the document?
          #   enumerable.include?(document)
          #
          # @param [ Document ] doc The document to check.
          #
          # @return [ true | false ] If the document is in the target.
          def include?(doc)
            return super unless _unloaded
            _unloaded.where(_id: doc._id).exists? || _added.has_key?(doc._id)
          end

          # Inspection will just inspect the entries for nice array-style
          # printing.
          #
          # @example Inspect the enumerable.
          #   enumerable.inspect
          #
          # @return [ String ] The inspected enum.
          def inspect
            entries.inspect
          end

          # Return all the documents in the enumerable that have been _loaded or
          # _added.
          #
          # @note When passed a block it yields to each document.
          #
          # @example Get the in memory docs.
          #   enumerable.in_memory
          #
          # @return [ Array<Document> ] The in memory docs.
          def in_memory
            docs = (_loaded.values + _added.values)
            docs.each do |doc|
              yield(doc) if block_given?
            end
          end

          # Get the last document in the enumerable. Will check the new
          # documents first. Does not load the entire enumerable.
          #
          # @example Get the last document.
          #   enumerable.last
          #
          # @note Automatically adding a sort on _id when no other sort is
          #   defined on the criteria has the potential to cause bad performance issues.
          #   If you experience unexpected poor performance when using #first or #last,
          #   use #take instead.
          #   Be aware that #take won't guarantee order.
          #
          # @param [ Integer ] limit The number of documents to return.
          #
          # @return [ Document ] The last document found.
          def last(limit = nil)
            _added.values.try(:last) ||
                _loaded.try(:values).try(:last) ||
                _added[(ul = _unloaded.try(:last, limit)).try(:_id)] ||
                ul
          end

          # Loads all the documents in the enumerable from the database.
          #
          # @example Load all the documents.
          #   enumerable.load_all!
          #
          # @return [ true ] That the enumerable is _loaded.
          alias :load_all! :entries

          # Has the enumerable been _loaded? This will be true if the criteria has
          # been executed or we manually load the entire thing.
          #
          # @example Is the enumerable _loaded?
          #   enumerable._loaded?
          #
          # @return [ true | false ] If the enumerable has been _loaded.
          def _loaded?
            !!@executed
          end

          # Provides the data needed to Marshal.dump an enumerable proxy.
          #
          # @example Dump the proxy.
          #   Marshal.dump(proxy)
          #
          # @return [ Array<Object> ] The dumped data.
          def marshal_dump
            [_added, _loaded, _unloaded, @executed]
          end

          # Loads the data needed to Marshal.load an enumerable proxy.
          #
          # @example Load the proxy.
          #   Marshal.load(proxy)
          #
          # @return [ Array<Object> ] The dumped data.
          def marshal_load(data)
            @_added, @_loaded, @_unloaded, @executed = data
          end

          # Reset the enumerable back to its persisted state.
          #
          # @example Reset the enumerable.
          #   enumerable.reset
          #
          # @return [ false ] Always false.
          def reset
            _loaded.clear
            _added.clear
            @executed = false
          end

          # Resets the underlying unloaded criteria object with a new one. Used
          # my HABTM associations to keep the underlying array in sync.
          #
          # @example Reset the unloaded documents.
          #   enumerable.reset_unloaded(criteria)
          #
          # @param [ Criteria ] criteria The criteria to replace with.
          def reset_unloaded(criteria)
            @_unloaded = criteria if _unloaded.is_a?(Criteria)
          end

          # Does this enumerable respond to the provided method?
          #
          # @example Does the enumerable respond to the method?
          #   enumerable.respond_to?(:sum)
          #
          # @param [ String | Symbol ] name The name of the method.
          # @param [ true | false ] include_private Whether to include private
          #   methods.
          #
          # @return [ true | false ] Whether the enumerable responds.
          def respond_to?(name, include_private = false)
            [].respond_to?(name, include_private) || super
          end

          # Gets the total size of this enumerable. This is a combination of all
          # the persisted and unpersisted documents.
          #
          # @example Get the size.
          #   enumerable.size
          #
          # @return [ Integer ] The size of the enumerable.
          def size
            count = (_unloaded ? _unloaded.count : _loaded.count)
            if count.zero?
              count + _added.count
            else
              count + _added.values.count { |d| d.new_record? }
            end
          end

          alias :length :size

          # Send #to_json to the entries.
          #
          # @example Get the enumerable as json.
          #   enumerable.to_json
          #
          # @param [ Hash ] options Optional parameters.
          #
          # @return [ String ] The entries all _loaded as a string.
          def to_json(options = {})
            entries.to_json(options)
          end

          # Send #as_json to the entries, without encoding.
          #
          # @example Get the enumerable as json.
          #   enumerable.as_json
          #
          # @param [ Hash ] options Optional parameters.
          #
          # @return [ Hash ] The entries all _loaded as a hash.
          def as_json(options = {})
            entries.as_json(options)
          end

          # Return all the unique documents in the enumerable.
          #
          # @note This operation loads all documents from the database.
          #
          # @example Get all the unique documents.
          #   enumerable.uniq
          #
          # @return [ Array<Document> ] The unique documents.
          def uniq
            entries.uniq
          end

          private

          def set_base(document)
            if @_association.is_a?(Referenced::HasMany)
              document.set_relation(@_association.inverse, @_base) if @_association
            end
          end

          ruby2_keywords def method_missing(name, *args, &block)
            entries.send(name, *args, &block)
          end

          def unloaded_documents
            if _unloaded.selector._mongoid_unsatisfiable_criteria?
              []
            else
              _unloaded
            end
          end
        end
      end
    end
  end
end
