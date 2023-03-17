# frozen_string_literal: true

module Mongoid

  # This module contains behavior for adding shard key fields to updates.
  module Shardable
    extend ActiveSupport::Concern

    included do
      # Returns the list of shard key fields, if shard key was declared on
      # this model. If no shard key was declared, returns an empty array.
      #
      # @return [ Array<Symbol> ] List of shard key fields.
      # @api public
      cattr_accessor :shard_key_fields
      self.shard_key_fields = []

      # Returns the shard configuration, which is a hash with the following
      # (symbol) keys:
      #
      # - keys: A hash mapping (symbol) field names to values, defining the
      #   shard key. Values can be either the integer 1 for ranged sharding
      #   or the string "hashed" for hashed sharding.
      # - options: A hash containing options for shardCollections command.
      #
      # If shard key was not declared via the +shard_key+ macro, +shard_config+
      # attribute is nil.
      #
      # @example Get the shard configuration.
      #   Model.shard_config
      #   # => {key: {foo: 1, bar: 1}, options: {unique: true}}
      #
      # @return [ Hash | nil ] Shard configuration.
      # @api public
      cattr_accessor :shard_config
    end

    # Get the shard key fields.
    #
    # @note Refactored from using delegate for class load performance.
    #
    # @example Get the shard key fields.
    #   model.shard_key_fields
    #
    # @return [ Array<String> ] The shard key field names.
    def shard_key_fields
      self.class.shard_key_fields
    end

    # Returns the selector that would match the defined shard keys. If
    # `prefer_persisted` is false (the default), it uses the current values
    # of the specified shard keys, otherwise, it will try to use whatever value
    # was most recently persisted.
    #
    # @param [ true | false ] prefer_persisted Whether to use the current
    #   value of the shard key fields, or to use their most recently persisted
    #   values.
    #
    # @return [ Hash ] The shard key selector.
    #
    # @api private
    def shard_key_selector(prefer_persisted: false)
      shard_key_fields.each_with_object({}) do |field, selector|
        selector[field.to_s] = shard_key_field_value(field.to_s, prefer_persisted: prefer_persisted)
      end
    end

    # Returns the selector that would match the existing version of this
    # document in the database.
    #
    # If the document is not persisted, this method uses the current values
    # of the shard key fields. If the document is persisted, this method
    # uses the values retrieved from the database.
    #
    # @return [ Hash ] The shard key selector.
    #
    # @api private
    def shard_key_selector_in_db
      shard_key_selector(prefer_persisted: true)
    end

    # Returns the value for the named shard key. If the field identifies
    # an embedded document, the key will be parsed and recursively evaluated.
    # If `prefer_persisted` is true, the value last persisted to the database
    # will be returned, regardless of what the current value of the attribute
    # may be.
    #
    # @param [String] field The name of the field to evaluate
    # @param [ true|false ] prefer_persisted Whether or not to prefer the
    #   persisted value over the current value.
    #
    # @return [ Object ] The value of the named field.
    #
    # @api private
    def shard_key_field_value(field, prefer_persisted:)
      if field.include?(".")
        relation, remaining = field.split(".", 2)
        send(relation)&.shard_key_field_value(remaining, prefer_persisted: prefer_persisted)
      elsif prefer_persisted && !new_record?
        attribute_was(field)
      else
        send(field)
      end
    end

    module ClassMethods

      # Specifies a shard key with the field(s) specified.
      #
      # @example Specify the shard key.
      #
      #   class Person
      #     include Mongoid::Document
      #     field :first_name, :type => String
      #     field :last_name, :type => String
      #
      #     shard_key first_name: 1, last_name: 1
      #   end
      def shard_key(*args)
        unless args.first.is_a?(Hash)
          # Shorthand syntax
          if args.last.is_a?(Hash)
            raise ArgumentError, 'Shorthand shard_key syntax does not permit options'
          end

          spec = Hash[args.map do |name|
            [name, 1]
          end]

          return shard_key(spec)
        end

        if args.length > 2
          raise ArgumentError, 'Full shard_key syntax requires 1 or 2 arguments'
        end

        spec, options = args

        spec = Hash[spec.map do |name, value|
          if value.is_a?(Symbol)
            value = value.to_s
          end
          [database_field_name(name).to_sym, value]
        end]

        self.shard_key_fields = spec.keys
        self.shard_config = {
          key: spec.freeze,
          options: (options || {}).dup.freeze,
        }.freeze
      end
    end
  end
end
