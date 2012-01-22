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
        message = case attrs
          when Hash
            message_for_attributes(attrs)
          else message_for_ids(attrs)
        end
        super(message)
      end

      private

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
      def message_for_ids(ids)
        translate(
          "document_not_found",
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
      def message_for_attributes(attrs)
        translate(
          "document_with_attributes_not_found",
          { :klass => klass.name, :attributes => attrs }
        )
      end
    end
  end
end
