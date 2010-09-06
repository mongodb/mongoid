# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Embedded #:nodoc:
        class Many < Binding

          # Binds the base object to the inverse of the relation. This is so we
          # are referenced to the actual objects themselves on both sides.
          #
          # This case sets the metadata on the inverse object as well as the
          # document itself.
          #
          # Example:
          #
          # <tt>person.addresses.bind</tt>
          # <tt>person.addresses = [ Address.new ]</tt>
          def bind_all
            target.each { |doc| bind_one(doc) }
          end

          # Binds a single document with the inverse relation. Used
          # specifically when appending to the proxy.
          #
          # Example:
          #
          # <tt>person.addresses.bind_one(address)</tt>
          def bind_one(doc)
            if bindable?(doc)
              doc.parentize(base)
              doc.send(metadata.inverse_setter(target), base)
            end
          end

          # Unbinds the base object and the inverse, caused by setting the
          # reference to nil.
          #
          # Example:
          #
          # <tt>person.addresses.unbind</tt>
          # <tt>person.addresses = nil</tt>
          def unbind
            if unbindable?
              target.each do |doc|
                doc.send(metadata.inverse_setter(target), nil)
              end
            end
          end

          private

          def inverse
            relation = target.to_a.first
            relation ? relation.send(metadata.inverse(target)) : nil
          end

          # Protection from infinite loops setting the inverse relations.
          # Checks if this document is not already equal to the target of the
          # inverse.
          #
          # Example:
          #
          # <tt>binding.bindable?</tt>
          #
          # Returns:
          #
          # true if the documents differ, false if not.
          def bindable?(doc)
            !base.equal?(doc.send(metadata.inverse(target)))
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
