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
          # @example Bind all the documents.
          #   person.addresses.bind
          #   person.addresses = [ Address.new ]
          def bind_all
            target.each { |doc| bind_one(doc) }
          end

          # Binds a single document with the inverse relation. Used
          # specifically when appending to the proxy.
          #
          # @example Bind one document.
          #   person.addresses.bind_one(address)
          #
          # @param [ Document ] doc The single document to bind.
          def bind_one(doc)
            if bindable?(doc)
              doc.parentize(base)
              name = metadata.inverse_setter(target)
              doc.send(name, base) unless name == "versions="
            end
          end

          # Unbinds the base object and the inverse, caused by setting the
          # reference to nil.
          #
          # @example Unbind the documents.
          #   person.addresses.unbind
          #   person.addresses = nil
          def unbind
            if unbindable?
              target.each do |doc|
                doc.send(metadata.inverse_setter(target), nil)
              end
            end
          end

          private

          # Determine what the inverse of this relation is.
          #
          # @example Get the inverse.
          #   binding.inverse
          #
          # @return [ Proxy ] The inverse of this relation.
          def inverse
            relation = target.first
            relation ? relation.send(metadata.inverse(target)) : nil
          end

          # Protection from infinite loops setting the inverse relations.
          # Checks if this document is not already equal to the target of the
          # inverse.
          #
          # @example Is this document bindable?
          #   binding.bindable?
          #
          # @param [ Document ] doc The document to check.
          #
          # @return [ Boolean ] True if the documents differ, false if not.
          def bindable?(doc)
            !base.equal?(doc.send(metadata.inverse(target)))
          end

          # Protection from infinite loops removing the inverse relations.
          # Checks if the target of the inverse is not already nil.
          #
          # @example Is the relation unbindable?
          #   binding.unbindable?
          #
          # @return [ Boolean ] True if the target is not nil, false if not.
          def unbindable?
            inverse && !inverse.target.nil?
          end
        end
      end
    end
  end
end
