# encoding: utf-8
module Mongoid #:nodoc
  module Components #:nodoc
    extend ActiveSupport::Concern
    included do
      # All modules that a +Document+ is composed of are defined in this
      # module, to keep the document class from getting too cluttered.
      include ActiveModel::Conversion
      include ActiveModel::Naming
      include ActiveModel::Serialization
      include ActiveModel::Serializers::JSON
      include ActiveModel::Serializers::Xml
      include Mongoid::Associations
      include Mongoid::Atomicity
      include Mongoid::Attributes
      include Mongoid::Collections
      include Mongoid::Dirty
      include Mongoid::Extras
      include Mongoid::Fields
      include Mongoid::Hierarchy
      include Mongoid::Indexes
      include Mongoid::Matchers
      include Mongoid::Memoization
      include Mongoid::Paths
      include Mongoid::Persistence
      include Mongoid::State
      include Mongoid::Validations
      include Mongoid::Callbacks
      extend ActiveModel::Translation
      extend Mongoid::Finders
      extend Mongoid::NamedScope
    end
  end
end
