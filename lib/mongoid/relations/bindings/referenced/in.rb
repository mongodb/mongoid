# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Referenced #:nodoc:

        # Binding class for all referenced_in relations.
        class In < Binding

          # Binds the base object to the inverse of the relation. This is so we
          # are referenced to the actual objects themselves on both sides.
          #
          # This case sets the metadata on the inverse object as well as the
          # document itself.
          #
          # @example Bind the documents.
          #   game.person.bind(:continue => true)
          #   game.person = Person.new
          #
          # @param [ Hash ] options The binding options.
          #
          # @option options [ true, false ] :continue Continue binding the inverse.
          # @option options [ true, false ] :binding Are we in build mode?
          #
          # @since 2.0.0.rc.1
          def bind(options = {})
            inverse = metadata.inverse(target)
            base.send(metadata.foreign_key_setter, target.id)
            if metadata.inverse_type
              base.send(metadata.inverse_type_setter, target.class.name)
            end
            if inverse
              base.metadata = target.reflect_on_association(inverse)
              if options[:continue]
                if base.referenced_many?
                  target.do_or_do_not(
                    inverse, false, OPTIONS
                  ).push(base, :binding => true, :continue => false)
                else
                  target.do_or_do_not(
                    metadata.inverse_setter(target),
                    base,
                    OPTIONS
                  )
                end
              end
            end
          end
          alias :bind_one :bind

          # Unbinds the base object and the inverse, caused by setting the
          # reference to nil.
          #
          # @example Unbind the document.
          #   game.person.unbind(:continue => true)
          #   game.person = nil
          #
          # @param [ Hash ] options The options to pass through.
          #
          # @option options [ true, false ] :continue Do we continue unbinding?
          #
          # @since 2.0.0.rc.1
          def unbind(options = {})
            base.do_or_do_not(metadata.foreign_key_setter, nil)
            if options[:continue]
              target.do_or_do_not(metadata.inverse_setter(target), nil, OPTIONS)
            end
          end
          alias :unbind_one :unbind
        end
      end
    end
  end
end
