# encoding: utf-8
module Mongoid #:nodoc:
  module Callbacks
    def self.included(base)
      base.class_eval do
        extend ActiveModel::Callbacks

        # Define all the callbacks that are accepted by the document.
        define_model_callbacks \
          :create,
          :destroy,
          :save,
          :update,
          :validation,
          :terminator => false
      end
    end
  end
end
