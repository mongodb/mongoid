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

        begin
          touches = _gather_touch_updates(Time.configured.now, field)
          _root.send(:persist_atomic_operations, '$set' => touches) if touches.present?
          _run_touch_callbacks_from_root
        ensure
          _clear_touch_updates(field)
        end

        true
      end

      # Recursively sets touchable fields on the current document and each of its
      # parents, including the root node. Returns the combined atomic $set
      # operations to be performed on the root document.
      #
      # @param [ Time ] now The timestamp used for synchronizing the touched time.
      # @param [ Symbol ] field The name of an additional field to update.
      #
      # @return [ Hash<String, Time> ] The touch operations to perform as an atomic $set.
      #
      # @api private
      def _gather_touch_updates(now, field = nil)
        field = database_field_name(field)
        write_attribute(:updated_at, now) if respond_to?("updated_at=")
        write_attribute(field, now) if field

        touches = _extract_touches_from_atomic_sets(field) || {}
        touches.merge!(_parent._gather_touch_updates(now) || {}) if _touchable_parent?
        touches
      end

      def _clear_touch_updates(field = nil)
        remove_change(:updated_at)
        remove_change(field) if field
        _parent._clear_touch_updates if _touchable_parent?
      end

      # Recursively runs :touch callbacks for the document and its parents,
      # beginning with the root document and cascading through each successive
      # child document.
      #
      # @api private
      def _run_touch_callbacks_from_root
        _parent._run_touch_callbacks_from_root if _touchable_parent?
        run_callbacks(:touch)
      end

      # Indicates whether the parent exists and is touchable.
      #
      # @api private
      def _touchable_parent?
        _parent && _association&.inverse_association&.touchable?
      end

      private

      # Extract and remove the atomic updates for the touch operation(s)
      # from the currently enqueued atomic $set operations.
      #
      # @param [ Symbol ] field The optional field.
      #
      # @return [ Hash ] The field-value pairs to update atomically.
      #
      # @api private
      def _extract_touches_from_atomic_sets(field = nil)
        updates = atomic_updates['$set']
        return {} unless updates

        touchable_keys = Set['updated_at', 'u_at']
        touchable_keys << field.to_s if field.present?

        updates.keys.each_with_object({}) do |key, touches|
          if touchable_keys.include?(key.split('.').last)
            touches[key] = updates.delete(key)
          end
        end
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

        # Embedded docs handle touch updates recursively within
        # the #touch method itself
        klass.after_touch method_name unless association.embedded?
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
              # This looks up touch_field at runtime, rather than at method definition time.
              # If touch_field is nil, it will only touch the default field (updated_at).
              relation.touch(association.touch_field)
            end
          end
        end
      end
      method_name.to_sym
    end
  end
end
