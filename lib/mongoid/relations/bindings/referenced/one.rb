# encoding: utf-8
module Mongoid
  module Relations
    module Bindings
      module Referenced

        # Binding class for references_one relations.
        class One < Binding

          # Binds the base object to the inverse of the relation. This is so we
          # are referenced to the actual objects themselves on both sides.
          #
          # This case sets the metadata on the inverse object as well as the
          # document itself.
          #
          # @example Bind the document.
          #   person.game.bind(:continue => true)
          #   person.game = Game.new
          #
          # @since 2.0.0.rc.1
          def bind_one
            binding do
              bind_from_relational_parent(target)
            end
          end

          # Unbinds the base object and the inverse, caused by setting the
          # reference to nil.
          #
          # @example Unbind the document.
          #   person.game.unbind(:continue => true)
          #   person.game = nil
          #
          # @since 2.0.0.rc.1
          def unbind_one
            binding do
              unbind_from_relational_parent(target)
            end
          end
        end
      end
    end
  end
end
