# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Referenced #:nodoc:
        class Many < Binding

          # Binds the base object to the inverse of the relation. This is so we
          # are referenced to the actual objects themselves on both sides.
          #
          # This case sets the metadata on the inverse object as well as the
          # document itself.
          #
          # @example Bind the relation.
          #   person.posts.bind_all
          #   person.posts = [ Post.new ]
          def bind_all
            target.each { |doc| bind_one(doc) } if bindable?(base)
          end

          # Binds a single document with the inverse relation. Used
          # specifically when appending to the proxy.
          #
          # @example Bind one document.
          #   person.posts.bind_one(post)
          #
          # @param [ Document ] doc The document to bind.
          def bind_one(doc)
            doc.send(metadata.foreign_key_setter, base.id)
            doc.send(metadata.inverse_setter, base)
          end

          # Unbinds the base object to the inverse of the relation. This occurs
          # when setting a side of the relation to nil.
          #
          # @example Unbind the relation.
          #   person.posts.unbind
          def unbind
            obj = if unbindable?
              target.each do |doc|
                doc.send(metadata.foreign_key_setter, nil)
                doc.send(metadata.inverse_setter, nil)
              end
            end
          end

          private

          # Determines if the supplied object is able to be bound - this is to
          # prevent infinite loops when setting inverse associations.
          #
          # @example Is the document bindable?
          #   binding.bindable?(document)
          #
          # @param [ Document ] doc The document to check.
          #
          # @return [ true, false ] True if bindable, false if not.
          def bindable?(doc)
            return false unless target.to_a.first
            !doc.equal?(inverse ? inverse.target : nil)
          end

          # Protection from infinite loops removing the inverse relations.
          # Checks if the target of the inverse is not already nil.
          #
          # @example Is the relation unbindable?
          #   binding.unbindable?
          #
          # @return [ true, false ] True if the target is not nil, false if not.
          def unbindable?
            inverse && !inverse.target.nil?
          end
        end
      end
    end
  end
end
