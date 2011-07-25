# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Referenced #:nodoc:

        # Binding class for all references_and_referenced_in_many relations.
        class ManyToMany < Binding

          # Binds the base object to the inverse of the relation. This is so we
          # are referenced to the actual objects themselves on both sides.
          #
          # This case sets the metadata on the inverse object as well as the
          # document itself.
          #
          # @example Bind all the documents.
          #   person.preferences.bind
          #   person.preferences = [ Preference.new ]
          #
          # @since 2.0.0.rc.1
          def bind
            target.each { |doc| bind_one(doc) }
          end

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
                doc.do_or_do_not(inverse).push(base) if inverse
              end
            end
          end

          # Unbinds the base object and the inverse, caused by setting the
          # reference to nil.
          #
          # @example Unbind the documents.
          #   person.preferences.unbind
          #   person.preferences = nil
          #
          # @since 2.0.0.rc.1
          def unbind
            target.each { |doc| unbind_one(doc) }
          end

          # Unbind a single document.
          #
          # @example Unbind the document.
          #   person.preferences.unbind_one(document)
          #
          # @since 2.0.0.rc.1
          def unbind_one(doc)
            base.do_or_do_not(metadata.foreign_key).delete(doc.id)
            unless binding?
              binding do
                inverse = metadata.inverse(target)
                doc.do_or_do_not(inverse).delete(base) if inverse
              end
            end
          end
        end
      end
    end
  end
end
