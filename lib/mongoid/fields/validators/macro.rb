# frozen_string_literal: true

module Mongoid
  module Fields
    module Validators
      # Validates the params passed to the field macro.
      module Macro
        extend self

        OPTIONS = %i[
          as
          default
          identity
          label
          localize
          fallbacks
          association
          pre_processed
          subtype
          type
          overwrite
          encrypt
        ]

        # Validate the field definition.
        #
        # @example Validate the field definition.
        #   Macro.validate(Model, :name, { localized: true })
        #
        # @param [ Class ] klass The model class.
        # @param [ Symbol ] name The field name.
        # @param [ Hash ] options The provided options.
        def validate(klass, name, options)
          validate_field_name(klass, name)
          validate_name_uniqueness(klass, name, options)
          validate_options(klass, name, options)
        end

        # Validate the association definition.
        #
        # @example Validate the association definition.
        #   Macro.validate(Model, :name)
        #
        # @param [ Class ] klass The model class.
        # @param [ Symbol ] name The field name.
        # @param [ Hash ] options The provided options.
        def validate_relation(klass, name, _options = {})
          [ name, :"#{name}?", :"#{name}=" ].each do |n|
            raise Errors::InvalidRelation.new(klass, n) if Mongoid.destructive_fields.include?(n)
          end
        end

        # Determine if the field name is valid, if not raise an error.
        #
        # @example Check the field name.
        #   Macro.validate_field_name(Model, :name)
        #
        # @param [ Class ] klass The model class.
        # @param [ Symbol ] name The field name.
        #
        # @raise [ Errors::InvalidField ] If the name is not allowed.
        #
        # @api private
        def validate_field_name(klass, name)
          [ name, :"#{name}?", :"#{name}=" ].each do |n|
            raise Errors::InvalidField.new(klass, name, n) if Mongoid.destructive_fields.include?(n)
          end
        end

        private

        # Determine if the field name is unique, if not raise an error.
        #
        # @example Check the field name.
        #   Macro.validate_name_uniqueness(Model, :name, {})
        #
        # @param [ Class ] klass The model class.
        # @param [ Symbol ] name The field name.
        # @param [ Hash ] options The provided options.
        #
        # @raise [ Errors::InvalidField ] If the name is not allowed.
        #
        # @api private
        def validate_name_uniqueness(klass, name, options)
          return unless !options[:overwrite] && klass.fields.keys.include?(name.to_s)
          raise Errors::InvalidField.new(klass, name, name) if Mongoid.duplicate_fields_exception

          Mongoid.logger.warn("Overwriting existing field #{name} in class #{klass.name}.") if Mongoid.logger
        end

        # Validate that the field options are allowed.
        #
        # @api private
        #
        # @example Validate the field options.
        #   Macro.validate_options(Model, :name, { localized: true })
        #
        # @param [ Class ] klass The model class.
        # @param [ Symbol ] name The field name.
        # @param [ Hash ] options The provided options.
        #
        # @raise [ Errors::InvalidFieldOption ] If an option is invalid.
        def validate_options(klass, name, options)
          options.keys.each do |option|
            if !OPTIONS.include?(option) && !Fields.options.include?(option)
              raise Errors::InvalidFieldOption.new(klass, name, option, OPTIONS)
            end

            Mongoid::Warnings.warn_symbol_type_deprecated if option == :type && options[option] == Symbol
          end
        end
      end
    end
  end
end
