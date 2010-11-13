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
          # Example:
          #
          # <tt>person.posts.bind_all</tt>
          # <tt>person.posts = [ Post.new ]</tt>
          def bind_all
            target.each { |doc| bind_one(doc) } if bindable?(base)
          end

          # Binds a single document with the inverse relation. Used
          # specifically when appending to the proxy.
          #
          # Example:
          #
          # <tt>person.posts.bind_one(post)</tt>
          def bind_one(doc)
            doc.send(metadata.foreign_key_setter, base.id)
            doc.send(metadata.inverse_setter, base)
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
