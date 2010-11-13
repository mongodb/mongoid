# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Referenced #:nodoc:
        class ManyToMany < Binding

          # Binds the base object to the inverse of the relation. This is so we
          # are referenced to the actual objects themselves on both sides.
          #
          # This case sets the metadata on the inverse object as well as the
          # document itself.
          #
          # Example:
          #
          # <tt>person.preferences.bind_all</tt>
          # <tt>person.preferences = [ Preference.new ]</tt>
          def bind_all
            target.each { |doc| bind_one(doc) } if bindable?(base)
          end

          # Binds a single document with the inverse relation. Used
          # specifically when appending to the proxy.
          #
          # Example:
          #
          # <tt>person.preferences.bind_one(preference)</tt>
          def bind_one(doc)
            base.send(metadata.foreign_key).push(doc.id)
            doc.send(metadata.inverse(target)).push(base)
          end

          # Unbinds the base object to the inverse of the relation. This occurs
          # when setting a side of the relation to nil.
          #
          # Example:
          #
          # <tt>person.preferences.unbind</tt>
          def unbind_all
            target.each { |doc| unbind_one(doc) }
          end

          # Unbinds a single document from the relation. Removes both the
          # object and the foreign key from both sides.
          #
          # Example:
          #
          # <tt>binding.unbind_one(doc)</tt>
          #
          # Options:
          #
          # doc: The document to unbind.
          def unbind_one(doc)
            if unbindable?(doc)
              base.send(metadata.foreign_key).delete(doc.id)
              doc.send(metadata.inverse(target)).delete(base)
            end
          end

          private

          # Determines if the supplied object is able to be bound - this is to
          # prevent infinite loops when setting inverse associations.
          #
          # Options:
          #
          # object: The object to check if it can be bound.
          #
          # Returns:
          #
          # true if bindable.
          def bindable?(object)
            return false unless target.to_a.first
            !object.equal?(inverse ? inverse.target : nil)
          end

          # Protection from infinite loops removing the inverse relations.
          # Checks if the target of the inverse is not already nil.
          #
          # Example:
          #
          # <tt>binding.unbindable?(doc)</tt>
          #
          # Returns:
          #
          # true if the target is not nil, false if not.
          def unbindable?(doc)
            base.send(metadata.foreign_key).include?(doc.id)
          end
        end
      end
    end
  end
end
