# encoding: utf-8
module Mongoid
  module Errors

    # Default parent Mongoid error for all custom errors. This handles the base
    # key for the translations and provides the convenience method for
    # translating the messages.
    class MongoidError < StandardError

      attr_reader :problem, :summary, :resolution

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
        @problem = translate_problem(key, attributes)
        @summary = translate_summary(key, attributes)
        @resolution = translate_resolution(key, attributes)
        @problem_title = translate("message_title", {})
        @summary_title = translate("summary_title", {})
        @resolution_title = translate("resolution_title", {})


        "\n#{@problem_title}:\n  #{@problem}"+
        "\n#{@summary_title}:\n  #{@summary}"+
        "\n#{@resolution_title}:\n  #{@resolution}"
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
        ::I18n.translate("#{BASE_KEY}.#{key}", options)
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
      def translate_problem(key, attributes)
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
      def translate_summary(key, attributes)
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
      def translate_resolution(key, attributes)
        translate("#{key}.resolution", attributes)
      end
    end
  end
end
