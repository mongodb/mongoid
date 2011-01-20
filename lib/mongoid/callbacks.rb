# encoding: utf-8
module Mongoid #:nodoc:
  module Callbacks
    extend ActiveSupport::Concern
    included do
      extend ActiveModel::Callbacks
      include ActiveModel::Validations::Callbacks

      define_model_callbacks :initialize, :only => :after
      define_model_callbacks :create, :destroy, :save, :update
    end
  end
end
