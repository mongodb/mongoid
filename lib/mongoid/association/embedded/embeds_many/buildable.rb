module Mongoid
  module Association
    module Embedded
      class EmbedsMany

        # Builder class for embeds_many associations.
        #
        # @since 7.0
        module Buildable
          include Threaded::Lifecycle

          # Builds the document out of the attributes using the provided
          # association metadata. Instantiates through the factory in order
          # to make sure subclasses and allocation are used if fitting. This
          # case will return many documents.
          #
          # @example Build the documents.
          #   Builder.new(meta, attrs).build
          #
          # @param [ Object ] base The base object.
          # @param [ Object ] object The object to use to build the relation.
          # @param [ String ] type Not used in this context.
          #
          # @return [ Array<Document ] The documents.
          def build(base, object, type = nil)
            return [] if object.blank?
            return object if object.first.is_a?(Document)
            docs = []
            object.each do |attrs|
              if _loading? && base.persisted?
                docs.push(Factory.from_db(klass, attrs))
              else
                docs.push(Factory.build(klass, attrs))
              end
            end
            docs
          end
        end
      end
    end
  end
end
