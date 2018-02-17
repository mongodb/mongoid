# encoding: utf-8
module Mongoid

  # This module defines the finder methods that hang off the document at the
  # class level.
  #
  # @since 4.0.0
  module Findable
    extend Mongoid::Criteria::Queryable::Forwardable

    select_with :with_default_scope

    # These are methods defined on the criteria that should also be accessible
    # directly from the class level.
    delegate \
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
      :update_all, to: :with_default_scope

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

    # Find a +Document+ in several different ways.
    #
    # If a +String+ is provided, it will be assumed that it is a
    # representation of a Mongo::ObjectID and will attempt to find a single
    # +Document+ based on that id. If a +Symbol+ and +Hash+ is provided then
    # it will attempt to find either a single +Document+ or multiples based
    # on the conditions provided and the first parameter.
    #
    # @example Find a single document by an id.
    #   Person.find(BSON::ObjectId)
    #
    # @param [ Array ] args An assortment of finder options.
    #
    # @return [ Document, nil, Criteria ] A document or matching documents.
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
