# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Raised when querying the database for a document by a specific id or by
    # set of attributes which does not exist. If multiple ids were passed then
    # it will display all of those.
    class DocumentNotFound < MongoidError

      attr_reader :identifiers

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
        @identifiers = attrs
        super(
          compose_message(
            message_key,
            {
              :klass => klass.name,
              :identifiers => identifiers,
              :attributes => identifiers
            }
          )
        )
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
      def message_key
        case identifiers
          when Hash then "document_with_attributes_not_found"
          else "document_not_found"
        end
      end
    end
  end
end
