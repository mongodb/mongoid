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
        :save,
        :update,
        :validate,
        :terminator => false
    end
  end
end
