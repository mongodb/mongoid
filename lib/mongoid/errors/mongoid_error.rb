# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Default parent Mongoid error for all custom errors. This handles the base
    # key for the translations and provides the convenience method for
    # translating the messages.
    class MongoidError < StandardError
      BASE_KEY = "mongoid.errors.messages"

      # Given the key of the specific error and the options hash, translate the
      # message.
      #
      # Options:
      #
      # key: The key of the error in the locales.
      # options: The objects to pass to create the message.
      #
      # Returns:
      #
      # A localized error message string.
      def translate(key, options)
        ::I18n.translate("#{BASE_KEY}.#{key}", options)
      end
    end
  end
end
