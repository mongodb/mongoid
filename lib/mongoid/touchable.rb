# frozen_string_literal: true

module Mongoid
  module Touchable

    module InstanceMethods

      # Touch the document, in effect updating its updated_at timestamp and
      # optionally the provided field to the current time. If any belongs_to
      # associations exist with a touch option, they will be updated as well.
      #
      # @example Update the updated_at timestamp.
      #   document.touch
      #
      # @example Update the updated_at and provided timestamps.
      #   document.touch(:audited)
      #
      # @note This will not autobuild associations if those options are set.
      #
      # @param [ Symbol ] field The name of an additional field to update.
      #
      # @return [ true/false ] false if document is new_record otherwise true.
      def touch(field = nil)
        return false if _root.new_record?
        current = Time.configured.now
        field = database_field_name(field)
        write_attribute(:updated_at, current) if respond_to?("updated_at=")
        write_attribute(field, current) if field

        # If the document being touched is embedded, touch its parents
        # all the way through the composition hierarchy to the root object,
        # because when an embedded document is changed the write is actually
        # performed by the composition root. See MONGOID-3468.
        if _parent
          # This will persist updated_at on this document as well as parents.
          # TODO support passing the field name to the parent's touch method;
          # I believe it should be read out of
          # _association.inverse_association.options but inverse_association
          # seems to not always/ever be set here. See MONGOID-5014.
          _parent.touch

          if field
            # If we are told to also touch a field, perform a separate write
            # for that field. See MONGOID-5136.
            # In theory we should combine the writes, which would require
            # passing the fields to be updated to the parents - MONGOID-5142.
            sets = set_field_atomic_updates(field)
            selector = atomic_selector
            _root.collection.find(selector).update_one(positionally(selector, sets), session: _session)
          end
        else
          # If the current document is not embedded, it is composition root
          # and we need to persist the write here.
          touches = touch_atomic_updates(field)
          unless touches["$set"].blank?
            selector = atomic_selector
            _root.collection.find(selector).update_one(positionally(selector, touches), session: _session)
          end
        end

        # Callbacks are invoked on the composition root first and on the
        # leaf-most embedded document last.
        run_callbacks(:touch)
        true
      end
    end

    extend self

    # Add the association to the touchable associations if the touch option was
    # provided.
    #
    # @example Add the touchable.
    #   Model.define_touchable!(assoc)
    #
    # @param [ Association ] association The association metadata.
    #
    # @return [ Class ] The model class.
    def define_touchable!(association)
      name = association.name
      method_name = define_relation_touch_method(name, association)
      association.inverse_class.tap do |klass|
        klass.after_save method_name
        klass.after_destroy method_name
        klass.after_touch method_name
      end
    end

    private

    # Define the method that will get called for touching belongs_to
    # associations.
    #
    # @api private
    #
    # @example Define the touch association.
    #   Model.define_relation_touch_method(:band)
    #   Model.define_relation_touch_method(:band, :band_updated_at)
    #
    # @param [ Symbol ] name The name of the association.
    # @param [ Association ] association The association metadata.
    #
    # @return [ Symbol ] The method name.
    def define_relation_touch_method(name, association)
      relation_classes = if association.polymorphic?
                           association.send(:inverse_association_classes)
                         else
                           [ association.relation_class ]
                         end

      relation_classes.each { |c| c.send(:include, InstanceMethods) }
      method_name = "touch_#{name}_after_create_or_destroy"
      association.inverse_class.class_eval do
        define_method(method_name) do
          without_autobuild do
            if relation = __send__(name)
              if association.touch_field
                # Note that this looks up touch_field at runtime, rather than
                # at method definition time.
                relation.touch association.touch_field
              else
                relation.touch
              end
            end
          end
        end
      end
      method_name.to_sym
    end
  end
end
