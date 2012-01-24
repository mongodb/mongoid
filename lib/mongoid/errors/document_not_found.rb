# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Raised when querying the database for a document by a specific id or by
    # set of attributes which does not exist. If multiple ids were passed then
    # it will display all of those.
    class DocumentNotFound < MongoidError

      attr_reader :klass, :identifiers

      # Create hte new error.
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

      def compose_message
        "\nProblem:\n  #{problem}\n"+
        "Summary:\n  #{summary}\n"+
        "Resolution:\n  #{resolution}\n"
      end

      private

      def problem
        case identifiers
        when Hash
          problem_for_attributes
        else
          problem_for_ids
        end
      end

      def summary
        translate("document_not_found.summary", { :klass => klass.name })
      end

      def resolution
        translate("document_not_found.resolution", { :klass => klass.name })
      end

      # Create the message for id searches.
      #
      # @example Create the message.
      #   error.message_for_ids(1)
      #
      # @param [ Array, Object ] ids The id or ids.
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
      #   error.message_for_attributes(:foo => "bar")
      #
      # @param [ Hash ] attrs The attributes.
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
