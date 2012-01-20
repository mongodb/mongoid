# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Raised when querying the database for a document by a specific id or by
    # set of attributes which does not exist. If multiple ids were passed then
    # it will display all of those.
    #
    # @example Create the error.
    #   DocumentNotFound.new(Person, ["1", "2"])
    #
    # @example Create the error with attributes instead of ids
    #   DocumentNotFound.new(Person, :ssn => "1234", :name => "Helen")
    class DocumentNotFound < MongoidError

      attr_reader :klass, :identifiers

      def initialize(klass, attrs)
        @klass = klass
        message = case attrs
          when Array then message_for_ids(attrs.join(","))
          when Hash  then message_for_attributes(attrs.to_s)
          else            message_for_ids(attrs)
        end

        super(message)
      end

      private
      def message_for_ids(ids)
        @identifiers = ids
        translate(
          "document_not_found",
          { :klass => klass.name, :identifiers => identifiers }
        )
      end

      def message_for_attributes(attrs)
        translate(
          "document_with_attributes_not_found",
          { :klass => klass.name, :attributes => attrs }
        )
      end
    end
  end
end
