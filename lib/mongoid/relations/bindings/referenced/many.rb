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
          # @param [ Hash ] options The binding options.
          #
          # @option options [ true, false ] :continue Continue binding the inverse.
          # @option options [ true, false ] :building Are we in build mode?
          #
          # @since 2.0.0.rc.1
          def bind(options = {})
            target.each { |doc| bind_one(doc, options) }
          end

          # Binds a single document with the inverse relation. Used
          # specifically when appending to the proxy.
          #
          # @example Bind one document.
          #   person.posts.bind_one(post)
          #
          # @param [ Document ] doc The single document to bind.
          # @param [ Hash ] options The binding options.
          #
          # @option options [ true, false ] :continue Continue binding the inverse.
          # @option options [ true, false ] :building Are we in build mode?
          #
          # @since 2.0.0.rc.1
          def bind_one(doc, options = {})
            if options[:continue]
              attempt(metadata.foreign_key_setter, doc, base.id)
              attempt(metadata.inverse_setter, doc, base, :continue => false)
            end
          end

          # Unbinds the base object and the inverse, caused by setting the
          # reference to nil.
          #
          # @example Unbind the documents.
          #   person.posts.unbind
          #   person.posts = nil
          #
          # @param [ Hash ] options The binding options.
          #
          # @option options [ true, false ] :continue Continue binding the inverse.
          # @option options [ true, false ] :building Are we in build mode?
          #
          # @since 2.0.0.rc.1
          def unbind(options = {})
            target.each { |doc| unbind_one(doc, options) }
          end

          # Unbind a single document.
          #
          # @example Unbind the document.
          #   person.posts.unbind_one(document)
          #
          # @param [ Hash ] options The binding options.
          #
          # @option options [ true, false ] :continue Continue binding the inverse.
          # @option options [ true, false ] :building Are we in build mode?
          #
          # @since 2.0.0.rc.1
          def unbind_one(doc, options = {})
            if options[:continue]
              attempt(metadata.foreign_key_setter, doc, nil)
              attempt(metadata.inverse_setter, doc, nil, :continue => false)
            end
          end
        end
      end
    end
  end
end
