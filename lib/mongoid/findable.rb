# frozen_string_literal: true
# encoding: utf-8

module Mongoid

  # This module defines the finder methods that hang off the document at the
  # class level.
  #
  # @since 4.0.0
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
      :find_one_and_delete,
      :find_one_and_replace,
      :find_one_and_update,
      :find_or_create_by,
      :find_or_create_by!,
      :find_or_initialize_by,
      :first_or_create,
      :first_or_create!,
      :first_or_initialize,
      :for_js,
      :geo_near,
      :includes,
      :map_reduce,
      :max,
      :min,
      :none,
      :pluck,
      :read,
      :sum,
      :text_search,
      :update,
      :update_all

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
    # @return [ true, false ] If the collection is empty.
    def empty?
      count == 0
    end

    # Returns true if there are on document in database based on the
    # provided arguments.
    #
    # @example Do any documents exist for the conditions?
    #   Person.exists?
    #
    # @return [ true, false ] If any documents exist for the conditions.
    def exists?
      with_default_scope.exists?
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
    # The +find+ method takes into account the default scope defined on the
    # model class, if any.
    #
    # @param [ Object | Array<Object> ] args The _id values to find or an
    #   array thereof.
    #
    # @return [ Document | Array<Document> | nil ] A document or matching documents.
    #
    # @raise Errors::DocumentNotFound If not all documents are found and
    #   the +raise_not_found_error+ Mongoid configuration option is truthy.
    def find(*args)
      with_default_scope.find(*args)
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
    # @return [ Document, nil ] A matching document.
    #
    # @since 3.0.0
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
    #
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
    # @return [ Document ] The first matching document.
    def first
      with_default_scope.first
    end
    alias :one :first

    # Find the last +Document+ given the conditions.
    #
    # @example Find the last document.
    #   Person.last
    #
    # @return [ Document ] The last matching document.
    def last
      with_default_scope.last
    end
  end
end
