# encoding: utf-8
module Mongoid
  module Errors

    # Default parent Mongoid error for all custom errors. This handles the base
    # key for the translations and provides the convenience method for
    # translating the messages.
    class MongoidError < StandardError

      BASE_KEY = "mongoid.errors.messages"

      # Compose the message.
      #
      # @example Create the message
      #   error.compose_message
      #
      # @return [ String ] The composed message.
      #
      # @since 3.0.0
      def compose_message(key, attributes)
        @problem = problem(key, attributes)
        @summary = summary(key, attributes)
        @resolution = resolution(key, attributes)

        "\nProblem:\n  #{@problem}"+
        "\nSummary:\n  #{@summary}"+
        "\nResolution:\n  #{@resolution}"
      end

      private

      # Given the key of the specific error and the options hash, translate the
      # message.
      #
      # @example Translate the message.
      #   error.translate("errors", :key => value)
      #
      # @param [ String ] key The key of the error in the locales.
      # @param [ Hash ] options The objects to pass to create the message.
      #
      # @return [ String ] A localized error message string.
      def translate(key, options)
        ::I18n.translate("#{BASE_KEY}.#{key}", { locale: :en }.merge(options))
      end

      # Create the problem.
      #
      # @example Create the problem.
      #   error.problem("error", {})
      #
      # @param [ String, Symbol ] key The error key.
      # @param [ Hash ] attributes The attributes to interpolate.
      #
      # @return [ String ] The problem.
      #
      # @since 3.0.0
      def problem(key, attributes)
        translate("#{key}.message", attributes)
      end

      # Create the summary.
      #
      # @example Create the summary.
      #   error.summary("error", {})
      #
      # @param [ String, Symbol ] key The error key.
      # @param [ Hash ] attributes The attributes to interpolate.
      #
      # @return [ String ] The summary.
      #
      # @since 3.0.0
      def summary(key, attributes)
        translate("#{key}.summary", attributes)
      end

      # Create the resolution.
      #
      # @example Create the resolution.
      #   error.resolution("error", {})
      #
      # @param [ String, Symbol ] key The error key.
      # @param [ Hash ] attributes The attributes to interpolate.
      #
      # @return [ String ] The resolution.
      #
      # @since 3.0.0
      def resolution(key, attributes)
        translate("#{key}.resolution", attributes)
      end
    end
  end
end
