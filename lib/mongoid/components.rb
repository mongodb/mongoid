# encoding: utf-8
require "mongoid/changeable"
require "mongoid/findable"
require "mongoid/indexable"
require "mongoid/inspectable"
require "mongoid/reloadable"
require "mongoid/scopable"
require "mongoid/shardable"

module Mongoid
  module Components
    extend ActiveSupport::Concern

    # All modules that a +Document+ is composed of are defined in this
    # module, to keep the document class from getting too cluttered.
    included do
      extend ActiveModel::Translation
      extend Mongoid::Findable
    end

    include ActiveModel::Conversion
    include ActiveModel::ForbiddenAttributesProtection
    include ActiveModel::Naming
    include ActiveModel::Serializers::JSON
    include ActiveModel::Serializers::Xml
    include Mongoid::Atomic
    include Mongoid::Changeable
    include Mongoid::Attributes
    include Mongoid::Evolvable
    include Mongoid::Fields
    include Mongoid::Hierarchy
    include Mongoid::Indexable
    include Mongoid::Inspectable
    include Mongoid::JSON
    include Mongoid::Matchers
    include Mongoid::NestedAttributes
    include Mongoid::Persistence
    include Mongoid::Relations
    include Mongoid::Reloadable
    include Mongoid::Scopable
    include Mongoid::Sessions
    include Mongoid::Serialization
    include Mongoid::Shardable
    include Mongoid::State
    include Mongoid::Threaded::Lifecycle
    include Mongoid::Timestamps::Timeless
    include Mongoid::Validations
    include Mongoid::Callbacks
    include Mongoid::Copyable
    include Mongoid::Equality

    MODULES = [
      Mongoid::Atomic,
      Mongoid::Attributes,
      Mongoid::Callbacks,
      Mongoid::Copyable,
      Mongoid::Changeable,
      Mongoid::Evolvable,
      Mongoid::Fields,
      Mongoid::Hierarchy,
      Mongoid::Indexable,
      Mongoid::Inspectable,
      Mongoid::JSON,
      Mongoid::Matchers,
      Mongoid::NestedAttributes,
      Mongoid::Persistence,
      Mongoid::Relations,
      Mongoid::Reloadable,
      Mongoid::Scopable,
      Mongoid::Serialization,
      Mongoid::Sessions,
      Mongoid::Shardable,
      Mongoid::State,
      Mongoid::Threaded::Lifecycle,
      Mongoid::Timestamps::Timeless,
      Mongoid::Validations,
      Mongoid::Equality
    ]

    class << self

      # Get a list of methods that would be a bad idea to define as field names
      # or override when including Mongoid::Document.
      #
      # @example Bad thing!
      #   Mongoid::Components.prohibited_methods
      #
      # @return [ Array<Symbol> ]
      #
      # @since 2.1.8
      def prohibited_methods
        @prohibited_methods ||= MODULES.flat_map do |mod|
          mod.instance_methods.map{ |m| m.to_sym }
        end
      end
    end
  end
end
