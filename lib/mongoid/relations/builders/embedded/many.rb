# encoding: utf-8
module Mongoid
  module Relations
    module Builders
      module Embedded
        class Many < Builder

          # Builds the document out of the attributes using the provided
          # metadata on the relation. Instantiates through the factory in order
          # to make sure subclasses and allocation are used if fitting. This
          # case will return many documents.
          #
          # @example Build the documents.
          #   Builder.new(meta, attrs).build
          #
          # @param [ String ] type Not used in this context.
          #
          # @return [ Array<Document ] The documents.
          def build(type = nil)
            return [] if object.blank?
            return object if object.first.is_a?(Document)
            docs = []
            object.each do |attrs|
              if _loading? && base.persisted?
                docs.push(Factory.from_map_or_db(klass, attrs))
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
