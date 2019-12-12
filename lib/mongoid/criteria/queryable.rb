# frozen_string_literal: true
# encoding: utf-8

require "mongoid/criteria/queryable/expandable"
require "mongoid/criteria/queryable/extensions"
require "mongoid/criteria/queryable/key"
require "mongoid/criteria/queryable/macroable"
require "mongoid/criteria/queryable/mergeable"
require "mongoid/criteria/queryable/smash"
require "mongoid/criteria/queryable/aggregable"
require "mongoid/criteria/queryable/pipeline"
require "mongoid/criteria/queryable/optional"
require "mongoid/criteria/queryable/options"
require "mongoid/criteria/queryable/selectable"
require "mongoid/criteria/queryable/selector"
require "mongoid/criteria/queryable/storable"

module Mongoid
  class Criteria

    # A queryable is any object that needs queryable's dsl injected into it to build
    # MongoDB queries. For example, a Mongoid::Criteria is an Queryable.
    #
    # @example Include queryable functionality.
    #   class Criteria
    #     include Queryable
    #   end
    module Queryable
      include Storable
      include Expandable
      include Mergeable
      include Aggregable
      include Selectable
      include Optional

      # @attribute [r] aliases The aliases.
      # @attribute [r] driver The Mongo driver being used.
      # @attribute [r] serializers The serializers.
      attr_reader :aliases, :driver, :serializers

      # Is this queryable equal to another object? Is true if the selector and
      # options are equal.
      #
      # @example Are the objects equal?
      #   queryable == criteria
      #
      # @param [ Object ] other The object to compare against.
      #
      # @return [ true, false ] If the objects are equal.
      #
      # @since 1.0.0
      def ==(other)
        return false unless other.is_a?(Queryable)
        selector == other.selector && options == other.options
      end

      # Initialize the new queryable. Will yield itself to the block if a block
      # is provided for objects that need additional behavior.
      #
      # @example Initialize the queryable.
      #   Queryable.new
      #
      # @param [ Hash ] aliases The optional field aliases.
      # @param [ Hash ] serializers The optional field serializers.
      # @param [ Symbol ] driver The driver being used.
      #
      # @since 1.0.0
      def initialize(aliases = {}, serializers = {}, driver = :mongo)
        @aliases, @driver, @serializers = aliases, driver.to_sym, serializers
        @options = Options.new(aliases, serializers)
        @selector = Selector.new(aliases, serializers)
        @pipeline = Pipeline.new(aliases)
        @aggregating = nil
        yield(self) if block_given?
      end

      # Handle the creation of a copy via #clone or #dup.
      #
      # @example Handle copy initialization.
      #   queryable.initialize_copy(criteria)
      #
      # @param [ Queryable ] other The original copy.
      #
      # @since 1.0.0
      def initialize_copy(other)
        @options = other.options.__deep_copy__
        @selector = other.selector.__deep_copy__
        @pipeline = other.pipeline.__deep_copy__
      end
    end
  end
end
