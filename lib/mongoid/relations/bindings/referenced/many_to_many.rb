# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Referenced #:nodoc:

        # Binding class for all references_and_referenced_in_many relations.
        class ManyToMany < Binding

          # Binds a single document with the inverse relation. Used
          # specifically when appending to the proxy.
          #
          # @example Bind one document.
          #   person.preferences.bind_one(preference)
          #
          # @param [ Document ] doc The single document to bind.
          #
          # @since 2.0.0.rc.1
          def bind_one(doc)
            base.push(metadata.foreign_key, doc.id)
            unless binding?
              binding do
                inverse = metadata.inverse(target)
                doc.send(inverse).push(base) if inverse
              end
            end
          end

          # Unbind a single document.
          #
          # @example Unbind the document.
          #   person.preferences.unbind_one(document)
          #
          # @since 2.0.0.rc.1
          def unbind_one(doc)
            base.pull(metadata.foreign_key, doc.id)
            unless binding?
              binding do
                inverse = metadata.inverse(target)
                doc.send(inverse).delete(base) if inverse
              end
            end
          end
        end
      end
    end
  end
end
