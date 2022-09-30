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

        touches = __gather_touch_updates(Time.configured.now, field)
        _root.send(:persist_atomic_operations, '$set' => touches) if touches.present?

        __run_touch_callbacks_from_root
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
      def __gather_touch_updates(now, field = nil)
        field = database_field_name(field)
        write_attribute(:updated_at, now) if respond_to?("updated_at=")
        write_attribute(field, now) if field

        touches = __extract_touches_from_atomic_sets(field) || {}
        touches.merge!(_parent.__gather_touch_updates(now) || {}) if __touchable_parent?
        touches
      end

      # Recursively runs :touch callbacks for the document and its parents,
      # beginning with the root document and cascading through each successive
      # child document.
      #
      # @api private
      def __run_touch_callbacks_from_root
        _parent.__run_touch_callbacks_from_root if __touchable_parent?
        run_callbacks(:touch)
      end

      def __touchable_parent?
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
      def __extract_touches_from_atomic_sets(field = nil)
        updates = atomic_updates['$set']
        return {} unless updates

        touchable_keys = %w(updated_at u_at)
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
              if association.touch_field
                # Note that this looks up touch_field at runtime, rather than
                # at method definition time.
                relation.touch(association.touch_field)
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
