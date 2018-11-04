# frozen_string_literal: true
# encoding: utf-8
module Mongoid
  module Touchable

    module InstanceMethods

      # Touch the document, in effect updating its updated_at timestamp and
      # optionally the provided field to the current time. If any belongs_to
      # relations exist with a touch option, they will be updated as well.
      #
      # @example Update the updated_at timestamp.
      #   document.touch
      #
      # @example Update the updated_at and provided timestamps.
      #   document.touch(:audited)
      #
      # @note This will not autobuild relations if those options are set.
      #
      # @param [ Symbol ] field The name of an additional field to update.
      #
      # @return [ true/false ] false if record is new_record otherwise true.
      #
      # @since 3.0.0
      def touch(field = nil)
        return false if _root.new_record?
        current = Time.now
        field = database_field_name(field)
        write_attribute(:updated_at, current) if respond_to?("updated_at=")
        write_attribute(field, current) if field

        touches = touch_atomic_updates(field)
        unless touches["$set"].blank?
          selector = atomic_selector
          _root.collection.find(selector).update_one(positionally(selector, touches), session: _session)
        end
        run_callbacks(:touch)
        true
      end
    end

    extend self

    # Add the association to the touchable relations if the touch option was
    # provided.
    #
    # @example Add the touchable.
    #   Model.define_touchable!(assoc)
    #
    # @param [ Association ] association The association metadata.
    #
    # @return [ Class ] The model class.
    #
    # @since 3.0.0
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
    # relations.
    #
    # @api private
    #
    # @example Define the touch relation.
    #   Model.define_relation_touch_method(:band)
    #   Model.define_relation_touch_method(:band, :band_updated_at)
    #
    # @param [ Symbol ] name The name of the relation.
    # @param [ Association ] association The association metadata.
    #
    # @since 3.1.0
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
      association.inverse_class.class_eval <<-TOUCH, __FILE__, __LINE__ + 1
          def #{method_name}
            without_autobuild do
              relation = __send__(:#{name})
              relation.touch #{":#{association.touch_field}" if association.touch_field} if relation
            end
          end
      TOUCH
      method_name.to_sym
    end
  end
end
