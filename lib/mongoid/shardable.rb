# frozen_string_literal: true
# encoding: utf-8

module Mongoid

  # This module contains behavior for adding shard key fields to updates.
  #
  # @since 4.0.0
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
    #
    # @since 1.0.0
    def shard_key_fields
      self.class.shard_key_fields
    end

    # Get the document selector with the defined shard keys.
    #
    # @example Get the selector for the shard keys.
    #   person.shard_key_selector
    #
    # @return [ Hash ] The shard key selector.
    #
    # @since 2.0.0
    def shard_key_selector
      selector = {}
      shard_key_fields.each do |field|
        selector[field.to_s] = new_record? ? send(field) : attribute_was(field)
      end
      selector
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
      #
      # @since 2.0.0
      def shard_key(name_or_key, *names, unique: false, options: {})
        key = if name_or_key.is_a?(Hash)
                name_or_key
              else
                Hash[([name_or_key] + names).flatten.map { |f| [f, 1] }]
              end
        key = Hash[key.map { |k, v| [self.database_field_name(k).to_sym, v] }]
        self.shard_key_fields = key.keys
        self.shard_config = {
          key: key,
          unique: unique,
          options: options,
        }
      end
    end
  end
end
