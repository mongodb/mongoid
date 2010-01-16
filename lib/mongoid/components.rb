# encoding: utf-8
module Mongoid #:nodoc
  module Components #:nodoc
    extend ActiveSupport::Concern
    included do
      # All modules that a +Document+ is composed of are defined in this
      # module, to keep the document class from getting too cluttered.
      include Associations
      include Attributes
      include Callbacks
      include Commands
      include Fields
      include Indexes
      include Matchers
      include Memoization
      include Observable
      include Validatable
      include ActiveModel::Conversion
      include ActiveModel::Serialization
      extend ActiveModel::Translation
      extend Finders
      extend NamedScope
    end
  end
end
