# frozen_string_literal: true

require "mongoid/changeable"
require "mongoid/collection_configurable"
require "mongoid/findable"
require "mongoid/indexable"
require "mongoid/inspectable"
require "mongoid/interceptable"
require "mongoid/matcher"
require "mongoid/matchable"
require "mongoid/persistable"
require "mongoid/reloadable"
require "mongoid/selectable"
require "mongoid/scopable"
require "mongoid/serializable"
require "mongoid/shardable"
require "mongoid/stateful"
require "mongoid/cacheable"
require "mongoid/traversable"
require "mongoid/validatable"

module Mongoid

  # This module provides inclusions of all behavior in a Mongoid document.
  module Composable
    extend ActiveSupport::Concern

    # All modules that a +Document+ is composed of are defined in this
    # module, to keep the document class from getting too cluttered.
    included do
      extend Findable
    end

    include ActiveModel::Model
    include ActiveModel::ForbiddenAttributesProtection
    include ActiveModel::Serializers::JSON
    include Atomic
    include Changeable
    include Clients
    include CollectionConfigurable
    include Attributes
    include Evolvable
    include Fields
    include Indexable
    include Inspectable
    include Matchable
    include Persistable
    include Association
    include Reloadable
    include Scopable
    include Selectable
    include Serializable
    include Shardable
    include Stateful
    include Cacheable
    include Threaded::Lifecycle
    include Traversable
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
      Matchable,
      Persistable,
      Association,
      Reloadable,
      Scopable,
      Serializable,
      Clients,
      Clients::Options,
      Shardable,
      Stateful,
      Cacheable,
      Threaded::Lifecycle,
      Traversable,
      Validatable,
      Equality,
      Association::Referenced::Syncable,
      Association::Macros,
      ActiveModel::Model,
      ActiveModel::Validations
    ]

    # These are methods names defined in included blocks that may conflict
    # with user-defined association or field names.
    # They won't be in the list of Module.instance_methods on which the
    # #prohibited_methods code below is dependent so we must track them
    # separately.
    #
    # @return [ Array<Symbol> ] A list of reserved method names.
    RESERVED_METHOD_NAMES = [ :fields,
                              :aliased_fields,
                              :localized_fields,
                              :index_specifications,
                              :shard_key_fields,
                              :nested_attributes,
                              :readonly_attributes,
                              :storage_options,
                              :cascades,
                              :cyclic,
                              :cache_timestamp_format
                            ]

    class << self

      # Get a list of methods that would be a bad idea to define as field names
      # or override when including Mongoid::Document.
      #
      # @example Bad thing!
      #   Mongoid::Components.prohibited_methods
      #
      # @return [ Array<Symbol> ]
      def prohibited_methods
        @prohibited_methods ||= MODULES.flat_map do |mod|
          mod.instance_methods.map(&:to_sym)
        end + RESERVED_METHOD_NAMES
      end
    end
  end
end
