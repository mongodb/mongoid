# encoding: utf-8
module Mongoid #:nodoc:
  module Callbacks
    extend ActiveSupport::Concern
    included do
      extend ActiveModel::Callbacks

      define_model_callbacks \
        :create,
        :destroy,
        :initialize,
        :save,
        :update,
        :validation
    end

    # Determine if the document is valid.
    #
    # @example Is the document valid?
    #   person.valid?
    #
    # @return [ true, false ] True if valid, false if not.
    def valid?(*)
      _run_validation_callbacks { super }
    end
  end
end
