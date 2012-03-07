# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Referenced #:nodoc:

        # Binding class for references_many relations.
        class Many < Binding

          # Binds a single document with the inverse relation. Used
          # specifically when appending to the proxy.
          #
          # @example Bind one document.
          #   person.posts.bind_one(post)
          #
          # @param [ Document ] doc The single document to bind.
          #
          # @since 2.0.0.rc.1
          def bind_one(doc)
            binding do
              check_inverse!(doc)
              bind_foreign_key(doc, base.id)
              bind_polymorphic_type(doc, base.class.model_name)
              bind_inverse(doc, base)
              bind_inverse_of_field(doc)
            end
          end

          # Unbind a single document.
          #
          # @example Unbind the document.
          #   person.posts.unbind_one(document)
          #
          # @param [ Document ] document The document to unbind.
          #
          # @since 2.0.0.rc.1
          def unbind_one(doc)
            binding do
              check_inverse!(doc)
              bind_foreign_key(doc, nil)
              bind_polymorphic_type(doc, nil)
              bind_inverse(doc, nil)
              bind_inverse_of_field(doc, true)
            end
          end
        end
      end
    end
  end
end
