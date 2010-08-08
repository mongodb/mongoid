# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded #:nodoc:
      module Builders #:nodoc:
        class Many < Builder #:nodoc:

          # Builds the document out of the attributes using the provided
          # metadata on the relation. Instantiates through the factory in order
          # to make sure subclasses and allocation are used if fitting. This
          # case will return many documents.
          #
          # Example:
          #
          # <tt>Builder.new(meta, attrs).build</tt>
          #
          # Returns:
          #
          # An +Array+ of +Documents+.
          def build
            return @object if @object.first.is_a?(Document)
            @object.inject([]) do |documents, attrs|
              documents.tap do |docs|
                docs << Mongoid::Factory.build(@metadata.klass, attrs)
              end
            end
          end
        end
      end
    end
  end
end
