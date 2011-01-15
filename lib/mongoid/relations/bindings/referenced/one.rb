# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Referenced #:nodoc:

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
          # @param [ Hash ] options The options to pass through.
          #
          # @option options [ true, false ] :continue Do we continue binding?
          # @option options [ true, false ] :binding Are we in build mode?
          #
          # @since 2.0.0.rc.1
          def bind(options = {})
            if options[:continue]
              target.do_or_do_not(metadata.foreign_key_setter, base.id)
              target.do_or_do_not(
                metadata.inverse_setter,
                base,
                OPTIONS
              )
            end
          end
          alias :bind_one :bind

          # Unbinds the base object and the inverse, caused by setting the
          # reference to nil.
          #
          # @example Unbind the document.
          #   person.game.unbind(:continue => true)
          #   person.game = nil
          #
          # @param [ Hash ] options The options to pass through.
          #
          # @option options [ true, false ] :continue Do we continue unbinding?
          # @option options [ true, false ] :binding Are we in build mode?
          #
          # @since 2.0.0.rc.1
          def unbind(options = {})
            if options[:continue]
              target.do_or_do_not(metadata.foreign_key_setter, nil)
              target.do_or_do_not(
                metadata.inverse_setter,
                nil,
                OPTIONS
              )
            end
          end
          alias :unbind_one :unbind
        end
      end
    end
  end
end
