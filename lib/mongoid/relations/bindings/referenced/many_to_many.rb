# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Referenced #:nodoc:

        # Binding class for all references_and_referenced_in_many relations.
        class ManyToMany < Binding

          # Binds the base object to the inverse of the relation. This is so we
          # are referenced to the actual objects themselves on both sides.
          #
          # This case sets the metadata on the inverse object as well as the
          # document itself.
          #
          # @example Bind all the documents.
          #   person.preferences.bind
          #   person.preferences = [ Preference.new ]
          #
          # @param [ Hash ] options The binding options.
          #
          # @option options [ true, false ] :continue Continue binding the inverse.
          # @option options [ true, false ] :binding Are we in build mode?
          #
          # @since 2.0.0.rc.1
          def bind(options = {})
            target.each { |doc| bind_one(doc, options) }
          end

          # Binds a single document with the inverse relation. Used
          # specifically when appending to the proxy.
          #
          # @example Bind one document.
          #   person.preferences.bind_one(preference)
          #
          # @param [ Document ] doc The single document to bind.
          # @param [ Hash ] options The binding options.
          #
          # @option options [ true, false ] :continue Continue binding the inverse.
          # @option options [ true, false ] :binding Are we in build mode?
          #
          # @since 2.0.0.rc.1
          def bind_one(doc, options = {})
            keys = base.do_or_do_not(metadata.foreign_key)
            keys.push(doc.id) unless keys.include?(doc.id)
            if options[:continue]
              inverse = metadata.inverse(target)
              if inverse
                doc.do_or_do_not(
                  inverse,
                  false,
                  OPTIONS
                ).push(base, :binding => true, :continue => false)
              end
            end
          end

          # Unbinds the base object and the inverse, caused by setting the
          # reference to nil.
          #
          # @example Unbind the documents.
          #   person.preferences.unbind
          #   person.preferences = nil
          #
          # @param [ Hash ] options The binding options.
          #
          # @option options [ true, false ] :continue Continue binding the inverse.
          # @option options [ true, false ] :binding Are we in build mode?
          #
          # @since 2.0.0.rc.1
          def unbind(options = {})
            target.each { |doc| unbind_one(doc, options) }
          end

          # Unbind a single document.
          #
          # @example Unbind the document.
          #   person.preferences.unbind_one(document)
          #
          # @param [ Hash ] options The binding options.
          #
          # @option options [ true, false ] :continue Continue binding the inverse.
          # @option options [ true, false ] :binding Are we in build mode?
          #
          # @since 2.0.0.rc.1
          def unbind_one(doc, options = {})
            base.do_or_do_not(metadata.foreign_key).delete(doc.id)
            if options[:continue]
              inverse = metadata.inverse(target)
              if inverse
                doc.do_or_do_not(
                  inverse, false, OPTIONS
                ).delete(base, :binding => true, :continue => false)
              end
            end
          end
        end
      end
    end
  end
end
