# encoding: utf-8
module Mongoid

  # This module defines the finder methods that hang off the document at the
  # class level.
  module Finders
    extend Origin::Forwardable

    select_with :with_default_scope
    delegate :aggregates, :avg, :each, :extras, :find_and_modify, :for_js,
      :includes, :map_reduce, :max, :min, :sum, :update, :update_all, to: :with_default_scope

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
    # @param [ Array ] args The conditions.
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
    #   Person.find(Moped::BSON::ObjectId)
    #
    # @param [ Array ] args An assortment of finder options.
    #
    # @return [ Document, nil, Criteria ] A document or matching documents.
    def find(*args)
      with_default_scope.find(*args)
    end

    # Find the first +Document+ given the conditions, or creates a new document
    # with the conditions that were supplied.
    #
    # @example Find or create the document.
    #   Person.find_or_create_by(:attribute => "value")
    #
    # @param [ Hash ] attrs The attributes to check.
    #
    # @return [ Document ] A matching or newly created document.
    def find_or_create_by(attrs = {}, &block)
      find_or(:create, attrs, &block)
    end

    # Find the first +Document+ given the conditions, or initializes a new document
    # with the conditions that were supplied.
    #
    # @example Find or initialize the document.
    #   Person.find_or_initialize_by(:attribute => "value")
    #
    # @param [ Hash ] attrs The attributes to check.
    #
    # @return [ Document ] A matching or newly initialized document.
    def find_or_initialize_by(attrs = {}, &block)
      find_or(:new, attrs, &block)
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
    # @since 3.0.0
    def find_by(attrs = {})
      result = where(attrs).first
      if result.nil? && Mongoid.raise_not_found_error
        raise(Errors::DocumentNotFound.new(self, attrs))
      end
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

    # Find the last +Document+ given the conditions.
    #
    # @example Find the last document.
    #   Person.last
    #
    # @return [ Document ] The last matching document.
    def last
      with_default_scope.last
    end

    module FindBy
      extend ActiveSupport::Concern

      included do
        class << self
          # Creates find_by, find_all_by, and find_by with _and_ iterated
          # infinite times.  The goal of this method is to try and tame the
          # learning curve when coming from ActiveRecord with traditional SQL
          # to Mongoid NoSQL.
          #
          # NOTE: This method creates an actual method with
          # define_singleton_method after it's initial call so that it does
          # not get in the way and slow down a Rails application after it's
          # initial call.
          #
          # @param *args [Any] The values of the fields you would like to search.
          # @returns an array of document (if find_all_by) or a single otherwise.
          #
          # @examples
          #
          #   Model.find_all_by_f1('value1')
          #   Model.find_by_f1('value1')
          #   Model.find_all_by_f1_and_f2_and_f3(true)
          #   Model.find_by_f1_and_f2('value1', 'value2')
          #   Model.find_all_by_field1_and_field1('value1', 'value2')
          #   Model.find_all_by_field1_and_field2_and_field3('value1', 'value2', 'value3')

          def method_missing(meth, *args)
            if meth =~ /\A(find_(?:all_)?by)_((?:[a-z0-9]_?)+)\Z/
              attrs = ($2.dup).split('_and_')
              attrs.each do |attr|
                unless fields.has_key?(attr.to_s)
                  super
                end
              end

              mongoid_meth = ($1.dup =~ /\Afind_all/ ? 'where' : 'find_by')
              class_eval(<<-SOURCE) unless methods.include?(meth)
                define_singleton_method(:#{meth}) do |#{attrs.join(', ')}|
                  #{mongoid_meth}(#{attrs.inject([]) { |obj, attr| obj << "#{attr}: #{attr}" }.join(', ')})
                end
              SOURCE

              return send(meth, *args)
            end

            super
          end
        end
      end
    end

    protected

    # Find the first object or create/initialize it.
    #
    # @example Find or perform an action.
    #   Person.find_or(:create, :name => "Dev")
    #
    # @param [ Symbol ] method The method to invoke.
    # @param [ Hash ] attrs The attributes to query or set.
    #
    # @return [ Document ] The first or new document.
    def find_or(method, attrs = {}, &block)
      where(attrs).first || send(method, attrs, &block)
    end
  end
end
