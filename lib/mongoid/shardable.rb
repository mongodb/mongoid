# encoding: utf-8
module Mongoid

  # This module contains behaviour for adding shard key fields to updates.
  #
  # @since 4.0.0
  module Shardable
    extend ActiveSupport::Concern

    included do
      cattr_accessor :shard_key_fields
      self.shard_key_fields = []
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
        selector[field.to_s] = send(field)
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
      #     shard_key :first_name, :last_name
      #   end
      #
      # @since 2.0.0
      def shard_key(*names)
        self.shard_key_fields = names
      end
    end
  end
end
