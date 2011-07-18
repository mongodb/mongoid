# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Referenced #:nodoc:

        # Binding class for references_many relations.
        class Many < Binding

          # Binds the base object to the inverse of the relation. This is so we
          # are referenced to the actual objects themselves on both sides.
          #
          # This case sets the metadata on the inverse object as well as the
          # document itself.
          #
          # @example Bind all the documents.
          #   person.posts.bind
          #   person.posts = [ Post.new ]
          #
          # @since 2.0.0.rc.1
          def bind
            target.in_memory.each { |doc| bind_one(doc) }
          end

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
            unless binding?
              binding do
                doc.do_or_do_not(metadata.foreign_key_setter, base.id)
                if metadata.type
                  doc.send(metadata.type_setter, base.class.model_name)
                end
                doc.do_or_do_not(metadata.inverse_setter, base)
              end
            end
          end

          # Unbinds the base object and the inverse, caused by setting the
          # reference to nil.
          #
          # @example Unbind the documents.
          #   person.posts.unbind
          #   person.posts = nil
          #
          # @since 2.0.0.rc.1
          def unbind
            target.in_memory.each { |doc| unbind_one(doc) }
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
            unless binding?
              binding do
                doc.do_or_do_not(metadata.foreign_key_setter, nil)
                if metadata.type
                  doc.send(metadata.type_setter, nil)
                end
                doc.do_or_do_not(metadata.inverse_setter, nil)
              end
            end
          end
        end
      end
    end
  end
end
