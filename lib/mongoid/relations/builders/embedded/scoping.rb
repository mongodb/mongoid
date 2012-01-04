# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Builders #:nodoc:
      module Embedded
        module Scoping

          def scope(docs)
            return docs unless metadata.order || metadata.klass.default_scoping?
            metadata.klass.criteria(true).order_by(metadata.order).tap do |crit|
              crit.documents = docs
            end
          end
        end
      end
    end
  end
end
