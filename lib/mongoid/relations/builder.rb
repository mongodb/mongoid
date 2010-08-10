# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    class Builder #:nodoc:

      # Instantiate the new builder for embeds one relation.
      #
      # Options:
      #
      # metadata: The metadata for the relation.
      # object: The attributes or document to build from.
      def initialize(metadata, object)
        @metadata, @object = metadata, object
      end

      protected
      # Do we need to perform a database query? It will be so if the object we
      # have is not a +Document+, +ActiveRecord::Base+, or
      # +DataMapper::Resource+
      #
      # Example:
      #
      # <tt>builder.query?</tt>
      #
      # Returns:
      #
      # true if the object responds to <tt>#attributes</tt>.
      def query?
        !@object.respond_to?(:attributes)
      end
    end
  end
end
