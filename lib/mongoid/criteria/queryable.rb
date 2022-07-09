# frozen_string_literal: true

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
      attr_reader :aliases

      # @attribute [r] serializers The serializers.
      attr_reader :serializers

      # Is this queryable equal to another object? Is true if the selector and
      # options are equal.
      #
      # @example Are the objects equal?
      #   queryable == criteria
      #
      # @param [ Object ] other The object to compare against.
      #
      # @return [ true | false ] If the objects are equal.
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
      # @param [ Hash ] associations The optional associations.
      # @param [ Hash ] aliased_associations The optional aliased associations.
      # @param [ Symbol ] driver The driver being used.
      #
      # @api private
      def initialize(aliases = {}, serializers = {}, associations = {}, aliased_associations = {})
        @aliases, @serializers = aliases, serializers
        @options = Options.new(aliases, serializers, associations, aliased_associations)
        @selector = Selector.new(aliases, serializers, associations, aliased_associations)
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
      def initialize_copy(other)
        @options = other.options.__deep_copy__
        @selector = other.selector.__deep_copy__
        @pipeline = other.pipeline.__deep_copy__
      end
    end
  end
end
