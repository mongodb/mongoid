# encoding: utf-8
module Mongoid #:nodoc
  module Components #:nodoc
    extend ActiveSupport::Concern

    # All modules that a +Document+ is composed of are defined in this
    # module, to keep the document class from getting too cluttered.
    included do
      extend ActiveModel::Translation
      extend Mongoid::Finders
    end

    include ActiveModel::Conversion
    include ActiveModel::MassAssignmentSecurity
    include ActiveModel::Naming
    include ActiveModel::Observing
    include ActiveModel::Serializers::JSON
    include ActiveModel::Serializers::Xml
    include Mongoid::Atomicity
    include Mongoid::Attributes
    include Mongoid::Collections
    include Mongoid::Copyable
    include Mongoid::DefaultScope
    include Mongoid::Dirty
    include Mongoid::Extras
    include Mongoid::Fields
    include Mongoid::Hierarchy
    include Mongoid::Indexes
    include Mongoid::Inspection
    include Mongoid::JSON
    include Mongoid::Keys
    include Mongoid::Matchers
    include Mongoid::NamedScope
    include Mongoid::NestedAttributes
    include Mongoid::Paths
    include Mongoid::Persistence
    include Mongoid::Relations
    include Mongoid::Safety
    include Mongoid::Serialization
    include Mongoid::Sharding
    include Mongoid::State
    include Mongoid::Validations
    include Mongoid::Callbacks
  end
end
