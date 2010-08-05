# encoding: utf-8
module Mongoid #:nodoc:
  module Callbacks
    extend ActiveSupport::Concern
    included do
      extend ActiveModel::Callbacks

      # Define all the callbacks that are accepted by the document.
      define_model_callbacks \
        :create,
        :destroy,
        :initialize,
        :save,
        :update,
        :validation
    end

    def valid?(*) #nodoc
      _run_validation_callbacks { super }
    end
  end
end
