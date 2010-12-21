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
          # @example Bind the relation.
          #   person.preferences.bind_all
          #   person.preferences = [ Preference.new ]
          def bind_all
            target.each { |doc| bind_one(doc) } if bindable?(base)
          end

          # Binds a single document with the inverse relation. Used
          # specifically when appending to the proxy.
          #
          # @example Bind one document.
          #   person.preferences.bind_one(preference)
          #
          # @param [ Document ] doc The document to bind.
          def bind_one(doc)
            base.send(metadata.foreign_key).push(doc.id)
            doc.send(metadata.inverse(target)).push(base)
          end

          # Unbinds the base object to the inverse of the relation. This occurs
          # when setting a side of the relation to nil.
          #
          # @example Unbind the relation.
          #   person.preferences.unbind
          def unbind_all
            target.each { |doc| unbind_one(doc) }
          end

          # Unbinds a single document from the relation. Removes both the
          # object and the foreign key from both sides.
          #
          # @example Unbind one document.
          #   binding.unbind_one(doc)
          #
          # @param [ Document ] doc The document to unbind.
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
          # @example Is the document bindable?
          #   binding.bindable?(document)
          #
          # @param [ Document ] doc The document to check if it can be bound.
          #
          # @return [ Boolean ] True if bindable, false if not.
          def bindable?(object)
            return false unless target.to_a.first
            !object.equal?(inverse ? inverse.target : nil)
          end

          # Protection from infinite loops removing the inverse relations.
          # Checks if the target of the inverse is not already nil.
          #
          # @example Is the document unbindable?
          #   binding.unbindable?(doc)
          #
          # @param [ Document ] doc The document to check.
          #
          # @return [ Boolean ] True if the target is not nil, false if not.
          def unbindable?(doc)
            base.send(metadata.foreign_key).include?(doc.id)
          end
        end
      end
    end
  end
end
