# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded #:nodoc:
      module Builders #:nodoc:
        class One #:nodoc:

          # Instantiate the new builder for embeds one relation.
          #
          # Options:
          #
          # metadata: The metadata for the relation.
          # attributes: The attributes to build from.
          def initialize(metadata, attributes)
            @metadata, @attributes = metadata, attributes
          end

          # Builds the document out of the attributes using the provided
          # metadata on the relation. Instantiates through the factory in order
          # to make sure subclasses and allocation are used if fitting.
          #
          # Example:
          #
          # <tt>Builder.new(meta, attrs).build</tt>
          #
          # Returns:
          #
          # A single +Document+.
          def build
            name = @metadata.name.to_s
            Mongoid::Factory.build(@metadata.klass, @attributes[name])
          end
        end
      end
    end
  end
end
