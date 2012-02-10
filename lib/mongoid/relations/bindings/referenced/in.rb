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
          # @since 2.0.0.rc.1
          def bind
            unless _binding?
              _binding do
                inverses = metadata.inverses(target)
                if inverses.count > 1 && base.send(metadata.foreign_key) == nil
                  # Raise an error if we're setting this attribute to an object, but we don't know on which inverse.
                  raise Errors::InvalidSetPolymorphicRelation.new(metadata.name, base.class.name, target.class.name)
                end
                
                inverse = metadata.inverse(target)
                
                base.you_must(metadata.foreign_key_setter, target.id)
                if metadata.inverse_type
                  base.you_must(metadata.inverse_type_setter, target.class.model_name)
                end
                
                if inverse
                  if set_base_metadata
                    if metadata.inverse_of_field
                      base.you_must(metadata.inverse_of_field_setter, base.metadata.name)
                    end
                  
                    if base.referenced_many?
                      target.send(inverse).push(base) unless Mongoid.using_identity_map?
                    else
                      target.do_or_do_not(metadata.inverse_setter(target), base)
                    end
                  end
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
          # @since 2.0.0.rc.1
          def unbind
            unless _binding?
              _binding do
                inverse = metadata.inverse(target)
                if !inverse && metadata.inverse_of_field
                  inverse = base.send(metadata.inverse_of_field)
                end
                
                base.you_must(metadata.foreign_key_setter, nil)
                if metadata.inverse_type
                  base.you_must(metadata.inverse_type_setter, nil)
                end
                if metadata.inverse_of_field
                  base.you_must(metadata.inverse_of_field_setter, nil)
                end
                
                if inverse
                  set_base_metadata
                  if base.referenced_many?
                    target.send(inverse).delete(base)
                  else
                    target.send("#{inverse}=", nil)
                  end
                end
              end
            end
          end
          alias :unbind_one :unbind

          private

          # Ensure that the metadata on the base is correct, for the cases
          # where we have multiple belongs to definitions and were are setting
          # different parents in memory in order.
          #
          # @api private
          #
          # @example Set the base metadata.
          #   binding.set_base_metadata
          #
          # @return [ true, false ] If the metadata changed.
          #
          # @since 2.4.4
          def set_base_metadata
            inverse_metadata = metadata.inverse_metadata(target)
            if inverse_metadata != metadata && !inverse_metadata.nil?
              base.metadata = inverse_metadata
            end
          end
        end
      end
    end
  end
end
