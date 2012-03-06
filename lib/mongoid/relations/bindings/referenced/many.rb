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
              doc.you_must(metadata.foreign_key_setter, base.id)
              if metadata.type
                doc.you_must(metadata.type_setter, base.class.model_name)
              end
              doc.send(metadata.inverse_setter, base)
              if inverse_metadata = metadata.inverse_metadata(doc)
                doc.do_or_do_not(inverse_metadata.inverse_of_field_setter, metadata.name)
              end
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
              doc.you_must(metadata.foreign_key_setter, nil)
              if metadata.type
                doc.you_must(metadata.type_setter, nil)
              end
              doc.send(metadata.inverse_setter, nil)
              if inverse_metadata = metadata.inverse_metadata(doc)
                doc.do_or_do_not(inverse_metadata.inverse_of_field_setter, nil)
              end
            end
          end

          private

          # Check if the inverse is properly defined.
          #
          # @api private
          #
          # @example Check the inverse definition.
          #   binding.check_inverse!(doc)
          #
          # @param [ Document ] doc The document getting bound.
          #
          # @raise [ Errors::InverseNotFound ] If no inverse found.
          #
          # @since 3.0.0
          def check_inverse!(doc)
            if !metadata.forced_nil_inverse? &&
              !doc.respond_to?(metadata.foreign_key_setter)
              raise Errors::InverseNotFound.new(
                base.class,
                metadata.name,
                doc.class,
                metadata.foreign_key
              )
            end
          end
        end
      end
    end
  end
end
