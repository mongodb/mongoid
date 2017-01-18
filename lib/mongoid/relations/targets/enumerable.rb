# encoding: utf-8
module Mongoid
  module Relations
    module Targets

      # This class is the wrapper for all relational associations that have a
      # target that can be a criteria or array of _loaded documents. This
      # handles both cases or a combination of the two.
      class Enumerable
        include ::Enumerable

        # The three main instance variables are collections of documents.
        #
        # @attribute [rw] _added Documents that have been appended.
        # @attribute [rw] _loaded Persisted documents that have been _loaded.
        # @attribute [rw] _unloaded A criteria representing persisted docs.
        attr_accessor :_added, :_loaded, :_unloaded

        delegate :is_a?, :kind_of?, to: []

        # Check if the enumerable is equal to the other object.
        #
        # @example Check equality.
        #   enumerable == []
        #
        # @param [ Enumerable ] other The other enumerable.
        #
        # @return [ true, false ] If the objects are equal.
        #
        # @since 2.1.0
        def ==(other)
          return false unless other.respond_to?(:entries)
          entries == other.entries
        end

        # Check equality of the enumerable against the provided object for case
        # statements.
        #
        # @example Check case equality.
        #   enumerable === Array
        #
        # @param [ Object ] other The object to check.
        #
        # @return [ true, false ] If the objects are equal in a case.
        #
        # @since 3.1.4
        def ===(other)
          other.class == Class ? (Array == other || Enumerable == other) : self == other
        end

        # Append a document to the enumerable.
        #
        # @example Append the document.
        #   enumerable << document
        #
        # @param [ Document ] document The document to append.
        #
        # @return [ Document ] The document.
        #
        # @since 2.1.0
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
        #
        # @since 2.1.0
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
        #
        # @since 2.1.6
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
        #
        # @since 2.1.0
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
        #
        # @since 2.1.0
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
        #
        # @since 2.1.0
        def each
          unless block_given?
            return to_enum
          end
          if _loaded?
            _loaded.each_pair do |id, doc|
              document = _added.delete(doc._id) || doc
              yield(document)
            end
          else
            unloaded_documents.each do |doc|
              document = _added.delete(doc._id) || _loaded.delete(doc._id) || doc
              _loaded[document._id] = document
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
        # @return [ true, false ] If the enumerable is empty.
        #
        # @since 2.1.0
        def empty?
          if _loaded?
            in_memory.count == 0
          else
            _unloaded.count + _added.count == 0
          end
        end

        # Get the first document in the enumerable. Will check the persisted
        # documents first. Does not load the entire enumerable.
        #
        # @example Get the first document.
        #   enumerable.first
        #
        # @return [ Document ] The first document found.
        #
        # @since 2.1.0
        def first
          _loaded.try(:values).try(:first) ||
            _added[(ul = _unloaded.try(:first)).try(:id)] ||
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
        # @param [ Criteria, Array<Document> ] target The wrapped object.
        #
        # @since 2.1.0
        def initialize(target)
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
        # @return [ true, false ] If the document is in the target.
        #
        # @since 3.0.0
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
        #
        # @since 2.1.0
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
        #
        # @since 2.1.0
        def in_memory
          docs = (_loaded.values + _added.values)
          docs.each { |doc| yield(doc) } if block_given?
          docs
        end

        # Get the last document in the enumerable. Will check the new
        # documents first. Does not load the entire enumerable.
        #
        # @example Get the last document.
        #   enumerable.last
        #
        # @return [ Document ] The last document found.
        #
        # @since 2.1.0
        def last
          _added.values.try(:last) ||
            _loaded.try(:values).try(:last) ||
            _added[(ul = _unloaded.try(:last)).try(:id)] ||
            ul
        end

        # Loads all the documents in the enumerable from the database.
        #
        # @example Load all the documents.
        #   enumerable.load_all!
        #
        # @return [ true ] That the enumerable is _loaded.
        #
        # @since 2.1.0
        alias :load_all! :entries

        # Has the enumerable been _loaded? This will be true if the criteria has
        # been executed or we manually load the entire thing.
        #
        # @example Is the enumerable _loaded?
        #   enumerable._loaded?
        #
        # @return [ true, false ] If the enumerable has been _loaded.
        #
        # @since 2.1.0
        def _loaded?
          !!@executed
        end

        # Provides the data needed to Marshal.dump an enumerable proxy.
        #
        # @example Dump the proxy.
        #   Marshal.dump(proxy)
        #
        # @return [ Array<Object> ] The dumped data.
        #
        # @since 3.0.15
        def marshal_dump
          [ _added, _loaded, _unloaded, @executed]
        end

        # Loads the data needed to Marshal.load an enumerable proxy.
        #
        # @example Load the proxy.
        #   Marshal.load(proxy)
        #
        # @return [ Array<Object> ] The dumped data.
        #
        # @since 3.0.15
        def marshal_load(data)
          @_added, @_loaded, @_unloaded, @executed = data
        end

        # Reset the enumerable back to its persisted state.
        #
        # @example Reset the enumerable.
        #   enumerable.reset
        #
        # @return [ false ] Always false.
        #
        # @since 2.1.0
        def reset
          _loaded.clear and _added.clear
          @executed = false
        end

        # Resets the underlying unloaded criteria object with a new one. Used
        # my HABTM relations to keep the underlying array in sync.
        #
        # @example Reset the unloaded documents.
        #   enumerable.reset_unloaded(criteria)
        #
        # @param [ Criteria ] criteria The criteria to replace with.
        #
        # @since 3.0.14
        def reset_unloaded(criteria)
          @_unloaded = criteria if _unloaded.is_a?(Criteria)
        end

        # Does this enumerable respond to the provided method?
        #
        # @example Does the enumerable respond to the method?
        #   enumerable.respond_to?(:sum)
        #
        # @param [ String, Symbol ] name The name of the method.
        # @param [ true, false ] include_private Whether to include private
        #   methods.
        #
        # @return [ true, false ] Whether the enumerable responds.
        #
        # @since 2.1.0
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
        #
        # @since 2.1.0
        def size
          count = (_unloaded ? _unloaded.count : _loaded.count)
          if count.zero?
            count + _added.count
          else
            count + _added.values.count{ |d| d.new_record? }
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
        #
        # @since 2.2.0
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
        #
        # @since 2.2.0
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
        #
        # @since 2.1.0
        def uniq
          entries.uniq
        end

        private

        def method_missing(name, *args, &block)
          entries.send(name, *args, &block)
        end

        def unloaded_documents
          _unloaded.selector.values.any?(&:blank_criteria?) ? [] : _unloaded
        end
      end
    end
  end
end
