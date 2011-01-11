# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Embedded #:nodoc:

        # Binding class for embeds_many relations.
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
          #   person.addresses.bind_one(address)
          #
          # @param [ Document ] doc The single document to bind.
          # @param [ Hash ] options The binding options.
          #
          # @option options [ true, false ] :continue Continue binding the inverse.
          # @option options [ true, false ] :building Are we in build mode?
          #
          # @since 2.0.0.rc.1
          def bind_one(doc, options = {})
            doc.parentize(base)
            if options[:continue]
              name = metadata.inverse_setter(target)
              doc.do_or_do_not(
                name,
                base,
                :building => true,
                :continue => false
              ) unless name == "versions="
            end
          end

          # Unbinds the base object and the inverse, caused by setting the
          # reference to nil.
          #
          # @example Unbind the documents.
          #   person.addresses.unbind
          #   person.addresses = nil
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
          #   person.addresses.unbind_one(document)
          #
          # @param [ Hash ] options The binding options.
          #
          # @option options [ true, false ] :continue Continue binding the inverse.
          # @option options [ true, false ] :building Are we in build mode?
          #
          # @since 2.0.0.rc.1
          def unbind_one(doc, options = {})
            if options[:continue]
              doc.do_or_do_not(metadata.inverse_setter(target), nil, :continue => false)
            end
          end
        end
      end
    end
  end
end
