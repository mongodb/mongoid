# frozen_string_literal: true

require "mongoid/validatable/macros"
require "mongoid/validatable/localizable"
require "mongoid/validatable/associated"
require "mongoid/validatable/format"
require "mongoid/validatable/length"
require "mongoid/validatable/queryable"
require "mongoid/validatable/presence"
require "mongoid/validatable/uniqueness"

module Mongoid

  # This module provides additional validations that ActiveModel does not
  # provide: validates_associated and validates_uniqueness_of.
  module Validatable
    extend ActiveSupport::Concern

    included do
      extend Macros
      include Macros
    end

    # Begin the associated validation.
    #
    # @example Begin validation.
    #   document.begin_validate
    def begin_validate
      Threaded.begin_validate(self)
    end

    # Exit the associated validation.
    #
    # @example Exit validation.
    #   document.exit_validate
    def exit_validate
      Threaded.exit_validate(self)
    end

    # Given the provided options, are we performing validations?
    #
    # @example Are we performing validations?
    #   document.performing_validations?(validate: true)
    #
    # @param [ Hash ] options The options to check.
    #
    # @option options [ true | false ] :validate Whether or not to validate.
    #
    # @return [ true | false ] If we are validating.
    def performing_validations?(options = {})
      options[:validate].nil? ? true : options[:validate]
    end

    # Overrides the default ActiveModel behavior since we need to handle
    # validations of associations slightly different than just calling the
    # getter.
    #
    # @example Read the value.
    #   person.read_attribute_for_validation(:addresses)
    #
    # @param [ Symbol ] attr The name of the field or association.
    #
    # @return [ Object ] The value of the field or the association.
    def read_attribute_for_validation(attr)
      attribute = database_field_name(attr)
      if relations.key?(attribute)
        begin_validate
        relation = without_autobuild { send(attr) }
        exit_validate
        relation.do_or_do_not(:in_memory) || relation
      elsif fields[attribute].try(:localized?)
        attributes[attribute]
      else
        send(attr)
      end
    end

    # Determine if the document is valid.
    #
    # @example Is the document valid?
    #   person.valid?
    #
    # @example Is the document valid in a context?
    #   person.valid?(:create)
    #
    # @param [ Symbol ] context The optional validation context.
    #
    # @return [ true | false ] True if valid, false if not.
    def valid?(context = nil)
      super context ? context : (new_record? ? :create : :update)
    end

    # Used to prevent infinite loops in associated validations.
    #
    # @example Is the document validated?
    #   document.validated?
    #
    # @return [ true | false ] Has the document already been validated?
    def validated?
      Threaded.validated?(self)
    end

    # Are we currently performing a validation that has a query?
    #
    # @example Are we validating with a query?
    #   document.validating_with_query?
    #
    # @return [ true | false ] If we are validating with a query.
    def validating_with_query?
      self.class.validating_with_query?
    end

    module ClassMethods

      # Adds an associated validator for the association if the validate option
      # was not provided or set to true.
      #
      # @example Set up validation.
      #   Person.validates_relation(association)
      #
      # @param [ Association ] association The association metadata.
      def validates_relation(association)
        if association.validate?
          validates_associated(association.name)
        end
      end

      # Add validation with the supplied validators for the provided fields
      # with options.
      #
      # @example Validate with a specific validator.
      #   validates_with MyValidator, on: :create
      #
      # @param [ ActiveModel::Validator..., Hash ] *args The validator classes
      #   and options hash.
      #
      # @note See ActiveModel::Validations::With for full options. This is
      #   overridden to add autosave functionality when presence validation is
      #   added.
      def validates_with(*args, &block)
        if args.first == PresenceValidator
          args.last[:attributes].each do |name|
            association = relations[name.to_s]
            if association && association.autosave?
              Association::Referenced::AutoSave.define_autosave!(association)
            end
          end
        end
        super
      end

      # Are we currently performing a validation that has a query?
      #
      # @example Are we validating with a query?
      #   Model.validating_with_query?
      #
      # @return [ true | false ] If we are validating with a query.
      def validating_with_query?
        Threaded.executing?("#{name}-validate-with-query")
      end
    end
  end
end
