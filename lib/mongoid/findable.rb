# frozen_string_literal: true

module Mongoid

  # This module defines the finder methods that hang off the document at the
  # class level.
  module Findable
    extend Forwardable

    def_delegators :with_default_scope, *(
      Criteria::Queryable::Selectable.forwardables +
      Criteria::Queryable::Optional.forwardables
    )

    # These are methods defined on the criteria that should also be accessible
    # directly from the class level.
    def_delegators :with_default_scope,
      :aggregates,
      :avg,
      :create_with,
      :distinct,
      :each,
      :each_with_index,
      :extras,
      :fifth,
      :fifth!,
      :find_one_and_delete,
      :find_one_and_replace,
      :find_one_and_update,
      :find_or_create_by,
      :find_or_create_by!,
      :find_or_initialize_by,
      :first!,
      :first_or_create,
      :first_or_create!,
      :first_or_initialize,
      :for_js,
      :fourth,
      :fourth!,
      :geo_near,
      :includes,
      :last!,
      :map_reduce,
      :max,
      :min,
      :none,
      :pick,
      :pluck,
      :read,
      :second,
      :second!,
      :second_to_last,
      :second_to_last!,
      :sum,
      :take,
      :take!,
      :tally,
      :text_search,
      :third,
      :third!,
      :third_to_last,
      :third_to_last!,
      :update,
      :update_all,

    # Returns a count of records in the database.
    # If you want to specify conditions use where.
    #
    # @example Get the count of matching documents.
    #   Person.count
    #   Person.where(title: "Sir").count
    #
    # @return [ Integer ] The number of matching documents.
    def count
      with_default_scope.count
    end

    # Returns an estimated count of records in the database.
    #
    # @example Get the count of matching documents.
    #   Person.estimated_count
    #
    # @return [ Integer ] The number of matching documents.
    def estimated_count
      with_default_scope.estimated_count
    end

    # Returns true if count is zero
    #
    # @example Are there no saved documents for this model?
    #   Person.empty?
    #
    # @return [ true | false ] If the collection is empty.
    def empty?
      count == 0
    end

    # Returns true if there are on document in database based on the
    # provided arguments.
    #
    # @example Do any documents exist for the conditions?
    #   Person.exists?
    #
    # @example Do any documents exist for given _id.
    #   Person.exists?(BSON::ObjectId(...))
    #
    # @example Do any documents exist for given conditions.
    #   Person.exists?(name: "...")
    #
    # @param [ Hash | Object | false ] id_or_conditions an _id to
    #   search for, a hash of conditions, nil or false.
    #
    # @return [ true | false ] If any documents exist for the conditions.
    #   Always false if passed nil or false.
    def exists?(id_or_conditions = :none)
      with_default_scope.exists?(id_or_conditions)
    end

    # Finds a +Document+ or multiple documents by their _id values.
    #
    # If a single non-Array argument is given, this argument is interpreted
    # as the _id value of a document to find. If there is a matching document
    # in the database, this document is returned; otherwise, if the
    # +raise_not_found_error+ Mongoid configuration option is truthy
    # (which is the default), +Errors::DocumentNotFound+ is raised, and if
    # +raise_not_found_error+ is falsy, +find+ returns +nil+.
    #
    # If multiple arguments are given, or an Array argument is given, the
    # array is flattened and each array element is interpreted as the _id
    # value of the document to find. Mongoid then attempts to retrieve all
    # documents with the provided _id values. The return value is an array
    # of found documents. Each document appears one time in the returned array,
    # even if its _id is given multiple times in the argument to +find+.
    # If the +raise_not_found_error+ Mongoid configuration option is truthy,
    # +Errors::DocumentNotFound+ exception is raised if any of the specified
    # _ids were not found in the database. If the ++raise_not_found_error+
    # Mongoid configuration option is falsy, only those documents which are
    # found are returned; if no documents are found, the return value is an
    # empty array.
    #
    # Note that MongoDB does not allow the _id field to be an array.
    #
    # The argument undergoes customary Mongoid type conversions based on
    # the type declared for the _id field. By default the _id field is a
    # +BSON::ObjectId+; this allows strings to be passed to +find+ and the
    # strings will be transparently converted to +BSON::ObjectId+ instances
    # during query construction.
    #
    # If this method is given a block, it delegates to +Enumerable#find+ and
    # returns the first document of those found by the current Crieria object
    # for which the block returns a truthy value. If both a block and ids are
    # given, the block is ignored and the documents for the given ids are
    # returned. If a block and a Proc are given, the method delegates to
    # +Enumerable#find+ and uses the proc as the default.
    #
    # The +find+ method takes into account the default scope defined on the
    # model class, if any.
    #
    # @note Each argument can be an individual id, an array of ids or
    #   a nested array. Each array will be flattened.
    #
    # @param [ [ Object | Array<Object> ]... ] *args The id(s) to find.
    #
    # @return [ Document | Array<Document> | nil ] A document or matching documents.
    #
    # @raise Errors::DocumentNotFound If not all documents are found and
    #   the +raise_not_found_error+ Mongoid configuration option is truthy.
    def find(*args, &block)
      empty_or_proc = args.empty? || (args.length == 1 && args.first.is_a?(Proc))
      if block_given? && empty_or_proc
        with_default_scope.find(*args, &block)
      else
        with_default_scope.find(*args)
      end
    end

    # Find the first +Document+ given the conditions.
    # If a matching Document is not found and
    # Mongoid.raise_not_found_error is true it raises
    # Mongoid::Errors::DocumentNotFound, return null nil elsewise.
    #
    # @example Find the document by attribute other than id
    #   Person.find_by(:username => "superuser")
    #
    # @param [ Hash ] attrs The attributes to check.
    #
    # @raise [ Errors::DocumentNotFound ] If no document found
    # and Mongoid.raise_not_found_error is true.
    #
    # @return [ Document | nil ] A matching document.
    def find_by(attrs = {})
      result = where(attrs).find_first
      if result.nil? && Mongoid.raise_not_found_error
        raise(Errors::DocumentNotFound.new(self, attrs))
      end
      yield(result) if result && block_given?
      result
    end

    # Find the first +Document+ given the conditions, or raises
    # Mongoid::Errors::DocumentNotFound
    #
    # @example Find the document by attribute other than id
    #   Person.find_by(:username => "superuser")
    #
    # @param [ Hash ] attrs The attributes to check.
    #
    # @raise [ Errors::DocumentNotFound ] If no document found.
    #
    # @return [ Document ] A matching document.
    def find_by!(attrs = {})
      result = where(attrs).find_first
      raise(Errors::DocumentNotFound.new(self, attrs)) unless result
      yield(result) if result && block_given?
      result
    end

    # Find the first +Document+ given the conditions.
    #
    # @example Find the first document.
    #   Person.first
    #
    # @param [ Integer ] limit The number of documents to return.
    #
    # @return [ Document ] The first matching document.
    def first(limit = nil)
      with_default_scope.first(limit)
    end
    alias :one :first

    # Find the last +Document+ given the conditions.
    #
    # @example Find the last document.
    #   Person.last
    #
    # @param [ Integer ] limit The number of documents to return.
    #
    # @return [ Document ] The last matching document.
    def last(limit = nil)
      with_default_scope.last(limit)
    end
  end
end
