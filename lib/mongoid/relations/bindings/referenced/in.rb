# encoding: utf-8
module Mongoid
  module Relations
    module Bindings
      module Referenced

        # Binding class for all referenced_in relations.
        class In < Binding

          # Binds the base object to the inverse of the relation. This is so we
          # are referenced to the actual objects themselves on both sides.
          #
          # This case sets the metadata on the inverse object as well as the
          # document itself.
          #
          # @example Bind the documents.
          #   game.person.bind(:continue => true)
          #   game.person = Person.new
          #
          # @since 2.0.0.rc.1
          def bind_one
            binding do
              check_inverses!(target)
              bind_foreign_key(base, record_id(target))
              bind_polymorphic_inverse_type(base, target.class.name)
              if inverse = metadata.inverse(target)
                if set_base_metadata
                  if base.referenced_many?
                    target.__send__(inverse).push(base)
                  else
                    target.set_relation(inverse, base)
                  end
                end
              end
            end
          end

          # Unbinds the base object and the inverse, caused by setting the
          # reference to nil.
          #
          # @example Unbind the document.
          #   game.person.unbind(:continue => true)
          #   game.person = nil
          #
          # @since 2.0.0.rc.1
          def unbind_one
            binding do
              inverse = metadata.inverse(target)
              bind_foreign_key(base, nil)
              bind_polymorphic_inverse_type(base, nil)
              if inverse
                set_base_metadata
                if base.referenced_many?
                  target.__send__(inverse).delete(base)
                else
                  target.set_relation(inverse, nil)
                end
              end
            end
          end
        end
      end
    end
  end
end
