# encoding: utf-8
require "mongoid/changeable"
require "mongoid/findable"
require "mongoid/indexable"
require "mongoid/inspectable"
require "mongoid/interceptable"
require "mongoid/persistable"
require "mongoid/reloadable"
require "mongoid/selectable"
require "mongoid/scopable"
require "mongoid/serializable"
require "mongoid/shardable"
require "mongoid/traversable"
require "mongoid/validatable"

module Mongoid

  # This module provides inclusions of all behaviour in a Mongoid document.
  #
  # @since 4.0.0
  module Composable
    extend ActiveSupport::Concern

    # All modules that a +Document+ is composed of are defined in this
    # module, to keep the document class from getting too cluttered.
    included do
      extend ActiveModel::Translation
      extend Findable
    end

    include ActiveModel::Conversion
    include ActiveModel::ForbiddenAttributesProtection
    include ActiveModel::Naming
    include ActiveModel::Serializers::JSON
    include ActiveModel::Serializers::Xml
    include Atomic
    include Changeable
    include Attributes
    include Evolvable
    include Fields
    include Indexable
    include Inspectable
    include Matchers
    include NestedAttributes
    include Persistable
    include Relations
    include Reloadable
    include Scopable
    include Selectable
    include Serializable
    include Sessions
    include Shardable
    include State
    include Threaded::Lifecycle
    include Traversable
    include Timestamps::Timeless
    include Validatable
    include Interceptable
    include Copyable
    include Equality

    MODULES = [
      Atomic,
      Attributes,
      Copyable,
      Changeable,
      Evolvable,
      Fields,
      Indexable,
      Inspectable,
      Interceptable,
      Matchers,
      NestedAttributes,
      Persistable,
      Relations,
      Reloadable,
      Scopable,
      Serializable,
      Sessions,
      Shardable,
      State,
      Threaded::Lifecycle,
      Timestamps::Timeless,
      Traversable,
      Validatable,
      Equality
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
