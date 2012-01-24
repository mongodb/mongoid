# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Raised when querying the database for a document by a specific id or by
    # set of attributes which does not exist. If multiple ids were passed then
    # it will display all of those.
    class DocumentNotFound < MongoidError

      attr_reader :klass, :identifiers

      # Create the new error.
      #
      # @example Create the error.
      #   DocumentNotFound.new(Person, ["1", "2"])
      #
      # @example Create the error with attributes instead of ids
      #   DocumentNotFound.new(Person, :ssn => "1234", :name => "Helen")
      #
      # @param [ Class ] klass The model class.
      # @param [ Hash, Array, Object ] attrs The attributes or ids.
      def initialize(klass, attrs)
        @klass, @identifiers = klass, attrs
        super(compose_message)
      end

      # Compose the message.
      #
      # @example Create the message
      #   error.compose_message
      #
      # @return [ String ] The composed message.
      #
      # @since 3.0.0
      def compose_message
        "\nProblem:\n  #{problem}"+
        "\nSummary:\n  #{summary}"+
        "\nResolution:\n  #{resolution}"
      end

      private

      # Create the problem.
      #
      # @example Create the problem.
      #   error.problem
      #
      # @return [ String ] The problem.
      #
      # @since 3.0.0
      def problem
        case identifiers
        when Hash
          problem_for_attributes
        else
          problem_for_ids
        end
      end

      # Create the summary.
      #
      # @example Create the summary.
      #   error.summary
      #
      # @return [ String ] The summary.
      #
      # @since 3.0.0
      def summary
        translate("document_not_found.summary", { :klass => klass.name })
      end

      # Create the resolution.
      #
      # @example Create the resolution.
      #   error.resolution
      #
      # @return [ String ] The resolution.
      #
      # @since 3.0.0
      def resolution
        translate("document_not_found.resolution", { :klass => klass.name })
      end

      # Create the message for id searches.
      #
      # @example Create the message.
      #   error.message_for_ids
      #
      # @return [ String ] The message.
      #
      # @since 3.0.0
      def problem_for_ids
        translate(
          "document_not_found.message",
          { :klass => klass.name, :identifiers => identifiers }
        )
      end

      # Create the message for attribute searches.
      #
      # @example Create the message.
      #   error.message_for_attributes
      #
      # @return [ String ] The message.
      #
      # @since 3.0.0
      def problem_for_attributes
        translate(
          "document_with_attributes_not_found",
          { :klass => klass.name, :attributes => identifiers }
        )
      end
    end
  end
end
