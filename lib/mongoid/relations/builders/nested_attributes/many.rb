# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Builders #:nodoc:
      module NestedAttributes #:nodoc:
        class Many

          # Create the new builder for nested attributes on one-to-one
          # relations.
          #
          # Example:
          #
          # <tt>One.new(metadata, attributes, options)</tt>
          #
          # Options:
          #
          # metadata: The relation metadata
          # attributes: The attributes hash to attempt to set.
          # options: The options defined.
          #
          # Returns:
          #
          # A new builder.
          def initialize(metadata, attributes, options)
            @attributes = attributes.with_indifferent_access
            @metadata = metadata
            @options = options
          end

          def build(parent)

          end
        end
      end
    end
  end
end
