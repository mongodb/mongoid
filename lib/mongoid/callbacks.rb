# encoding: utf-8
module Mongoid #:nodoc:
  module Callbacks
    def self.included(base)
      base.class_eval do
        include ActiveSupport::Callbacks

        # Define all the callbacks that are accepted by the document.
        define_callbacks \
          :before_create,
          :after_create,
          :before_destroy,
          :after_destroy,
          :before_save,
          :after_save,
          :before_update,
          :after_update,
          :before_validation,
          :after_validation
      end
    end
  end
end
