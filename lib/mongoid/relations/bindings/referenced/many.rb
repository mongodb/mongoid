# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Referenced #:nodoc:
        class Many < Binding

          # Binds the base object to the inverse of the relation. This is so we
          # are referenced to the actual objects themselves and dont hit the
          # database twice when setting the relations up.
          #
          # This essentially sets the foreign key and the object itself.
          #
          # Example:
          #
          # <tt>person.posts.bind</tt>
          def bind
            if bindable?(base)
              target.each do |doc|
                doc.send(metadata.foreign_key_setter, base.id)
                doc.send(metadata.inverse_setter, base)
              end
            end
          end

          # Unbinds the base object to the inverse of the relation. This occurs
          # when setting a side of the relation to nil.
          #
          # Example:
          #
          # <tt>person.posts.unbind</tt>
          def unbind
            obj = if unbindable?
              target.each do |doc|
                doc.send(metadata.foreign_key_setter, nil)
                doc.send(metadata.inverse_setter, nil)
              end
            end
          end

          # Protection from infinite loops removing the inverse relations.
          # Checks if the target of the inverse is not already nil.
          #
          # Example:
          #
          # <tt>binding.unbindable?</tt>
          #
          # Returns:
          #
          # true if the target is not nil, false if not.
          def unbindable?
            inverse && !inverse.target.nil?
          end
        end
      end
    end
  end
end
