# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      class HasMany

        # Binding class for has_many associations.
        class Binding
          include Bindable

          # Binds a single document with the inverse association. Used
          # specifically when appending to the proxy.
          #
          # @example Bind one document.
          #   person.posts.bind_one(post)
          def bind_one(doc)
            binding do
              bind_from_relational_parent(doc)
            end
          end

          # Unbind a single document.
          #
          # @example Unbind the document.
          #   person.posts.unbind_one(document)
          def unbind_one(doc)
            binding do
              unbind_from_relational_parent(doc)
            end
          end
        end
      end
    end
  end
end
