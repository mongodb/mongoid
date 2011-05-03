# encoding: utf-8
module Mongoid #:nodoc:
  module Callbacks
    extend ActiveSupport::Concern

    CALLBACKS = [
      :before_validation, :after_validation,
      :after_initialize, :after_build,
      :before_create, :around_create, :after_create,
      :before_destroy, :around_destroy, :after_destroy,
      :before_save, :around_save, :after_save,
      :before_update, :around_update, :after_update,
    ]

    included do
      extend ActiveModel::Callbacks
      include ActiveModel::Validations::Callbacks

      define_model_callbacks :initialize, :only => :after
      define_model_callbacks :build, :only => :after
      define_model_callbacks :create, :destroy, :save, :update
    end
  end
end
