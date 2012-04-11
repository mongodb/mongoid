# encoding: utf-8
module Mongoid #:nodoc:
  module Dirty #:nodoc:
    extend ActiveSupport::Concern

    # Get the changed attributes for the document.
    #
    # @example Get the changed attributes.
    #   model.changed
    #
    # @return [ Array<String> ] The changed attributes.
    #
    # @since 2.4.0
    def changed
      changed_attributes.keys
    end

    # Has the document changed?
    #
    # @example Has the document changed?
    #   model.changed?
    #
    # @return [ true, false ] If the document is changed.
    #
    # @since 2.4.0
    def changed?
      changes.values.any? { |val| val } || children_changed?
    end

    # Have any children (embedded documents) of this document changed?
    #
    # @example Have any children changed?
    #   model.children_changed?
    #
    # @return [ true, false ] If any children have changed.
    #
    # @since 2.4.1
    def children_changed?
      _children.any? do |child|
        child.changed?
      end
    end

    # Get the attribute changes.
    #
    # @example Get the attribute changes.
    #   model.changed_attributes
    #
    # @return [ Hash<String, Object> ] The attribute changes.
    #
    # @since 2.4.0
    def changed_attributes
      @changed_attributes ||= {}
    end

    # Get all the changes for the document.
    #
    # @example Get all the changes.
    #   model.changes
    #
    # @return [ Hash<String, Array<Object, Object> ] The changes.
    #
    # @since 2.4.0
    def changes
      Hash[changed.map do |attr|
        [attr, attribute_change(attr)]
      end].with_indifferent_access
    end

    # Call this method after save, so the changes can be properly switched.
    #
    # This will unset the memoized children array, set new record to
    # false, set the document as validated, and move the dirty changes.
    #
    # @example Move the changes to previous.
    #   person.move_changes
    #
    # @since 2.1.0
    def move_changes
      @_children = nil
      @previous_changes = changes
      Atomic::UPDATES.each do |update|
        send(update).clear
      end
      changed_attributes.clear
    end

    # Things that need to execute after a document has been persisted.
    #
    # @example Handle post persistence.
    #   document.post_persist
    #
    # @since 3.0.0
    def post_persist
      reset_persisted_children
      move_changes
      Threaded.clear_options!
    end

    # Get the previous changes on the document.
    #
    # @example Get the previous changes.
    #   model.previous_changes
    #
    # @return [ Hash<String, Array<Object, Object> ] The previous changes.
    #
    # @since 2.4.0
    def previous_changes
      @previous_changes ||= {}
    end

    # Remove a change from the dirty attributes hash. Used by the single field
    # atomic updators.
    #
    # @example Remove a flagged change.
    #   model.remove_change(:field)
    #
    # @param [ Symbol, String ] name The name of the field.
    #
    # @since 2.1.0
    def remove_change(name)
      changed_attributes.delete(name.to_s)
    end

    # Gets all the new values for each of the changed fields, to be passed to
    # a MongoDB $set modifier.
    #
    # @todo: Durran: Refactor 3.0
    #
    # @example Get the setters for the atomic updates.
    #   person = Person.new(:title => "Sir")
    #   person.title = "Madam"
    #   person.setters # returns { "title" => "Madam" }
    #
    # @return [ Hash ] A +Hash+ of atomic setters.
    def setters
      modifications = {}
      changes.each_pair do |name, changes|
        if changes
          old, new = changes
          field = fields[name]
          key = atomic_attribute_name(name) 
          if field && field.resizable?
            field.add_atomic_changes(
              self,
              name,
              key,
              modifications,
              new,
              old
            )
          else
            unless atomic_unsets.include?(key)
              modifications[key] = new
            end
          end
        end
      end
      modifications
    end

    private

    # Get the old and new value for the provided attribute.
    #
    # @example Get the attribute change.
    #   model.attribute_change("name")
    #
    # @param [ String ] attr The name of the attribute.
    #
    # @return [ Array<Object> ] The old and new values.
    #
    # @since 2.1.0
    def attribute_change(attr)
      [changed_attributes[attr], attributes[attr]] if attribute_changed?(attr)
    end

    # Determine if a specific attribute has changed.
    #
    # @example Has the attribute changed?
    #   model.attribute_changed?("name")
    #
    # @param [ String ] attr The name of the attribute.
    #
    # @return [ true, false ] Whether the attribute has changed.
    #
    # @since 2.1.6
    def attribute_changed?(attr)
      return false unless changed_attributes.has_key?(attr)
      changed_attributes[attr] != attributes[attr]
    end

    # Get whether or not the field has a different value from the default.
    #
    # @example Is the field different from the default?
    #   model.attribute_changed_from_default?
    #
    # @param [ String ] attr The name of the attribute.
    #
    # @return [ true, false ] If the attribute differs.
    #
    # @since 3.0.0
    def attribute_changed_from_default?(attr)
      field = fields[attr]
      return false unless field
      attributes[attr] != field.eval_default(self)
    end

    # Get the previous value for the attribute.
    #
    # @example Get the previous value.
    #   model.attribute_was("name")
    #
    # @param [ String ] attr The attribute name.
    #
    # @since 2.4.0
    def attribute_was(attr)
      attribute_changed?(attr) ? changed_attributes[attr] : attributes[attr]
    end

    # Flag an attribute as going to change.
    #
    # @example Flag the attribute.
    #   model.attribute_will_change!("name")
    #
    # @param [ String ] attr The name of the attribute.
    #
    # @return [ Object ] The old value.
    #
    # @since 2.3.0
    def attribute_will_change!(attr)
      unless changed_attributes.has_key?(attr)
        changed_attributes[attr] = read_attribute(attr)._deep_copy
      end
    end

    # Set the attribute back to it's old value.
    #
    # @example Reset the attribute.
    #   model.reset_attribute!("name")
    #
    # @param [ String ] attr The name of the attribute.
    #
    # @return [ Object ] The old value.
    #
    # @since 2.4.0
    def reset_attribute!(attr)
      attributes[attr] = changed_attributes[attr] if attribute_changed?(attr)
    end

    module ClassMethods #:nodoc:

      private

      # Generate all the dirty methods needed for the attribute.
      #
      # @example Generate the dirty methods.
      #   Model.create_dirty_methods("name", "name")
      #
      # @param [ String ] name The name of the field.
      # @param [ String ] name The name of the accessor.
      #
      # @return [ Module ] The fields module.
      #
      # @since 2.4.0
      def create_dirty_methods(name, meth)
        create_dirty_change_accessor(name, meth)
        create_dirty_change_check(name, meth)
        create_dirty_change_flag(name, meth)
        create_dirty_default_change_check(name, meth)
        create_dirty_previous_value_accessor(name, meth)
        create_dirty_reset(name, meth)
        create_dirty_reset(name, meth)
      end

      # Creates the dirty change accessor.
      #
      # @example Create the accessor.
      #   Model.create_dirty_change_accessor("name", "alias")
      #
      # @param [ String ] name The attribute name.
      # @param [ String ] meth The name of the accessor.
      #
      # @since 3.0.0
      def create_dirty_change_accessor(name, meth)
        generated_methods.module_eval do
          re_define_method("#{meth}_change") do
            attribute_change(name)
          end
        end
      end

      # Creates the dirty change check.
      #
      # @example Create the check.
      #   Model.create_dirty_change_check("name", "alias")
      #
      # @param [ String ] name The attribute name.
      # @param [ String ] meth The name of the accessor.
      #
      # @since 3.0.0
      def create_dirty_change_check(name, meth)
        generated_methods.module_eval do
          re_define_method("#{meth}_changed?") do
            attribute_changed?(name)
          end
        end
      end

      # Creates the dirty default change check.
      #
      # @example Create the check.
      #   Model.create_dirty_default_change_check("name", "alias")
      #
      # @param [ String ] name The attribute name.
      # @param [ String ] meth The name of the accessor.
      #
      # @since 3.0.0
      def create_dirty_default_change_check(name, meth)
        generated_methods.module_eval do
          re_define_method("#{meth}_changed_from_default?") do
            attribute_changed_from_default?(name)
          end
        end
      end

      # Creates the dirty change previous value accessor.
      #
      # @example Create the accessor.
      #   Model.create_dirty_previous_value_accessor("name", "alias")
      #
      # @param [ String ] name The attribute name.
      # @param [ String ] meth The name of the accessor.
      #
      # @since 3.0.0
      def create_dirty_previous_value_accessor(name, meth)
        generated_methods.module_eval do
          re_define_method("#{meth}_was") do
            attribute_was(name)
          end
        end
      end

      # Creates the dirty change flag.
      #
      # @example Create the flag.
      #   Model.create_dirty_change_flag("name", "alias")
      #
      # @param [ String ] name The attribute name.
      # @param [ String ] meth The name of the accessor.
      #
      # @since 3.0.0
      def create_dirty_change_flag(name, meth)
        generated_methods.module_eval do
          re_define_method("#{meth}_will_change!") do
            attribute_will_change!(name)
          end
        end
      end

      # Creates the dirty change reset.
      #
      # @example Create the reset.
      #   Model.create_dirty_reset("name", "alias")
      #
      # @param [ String ] name The attribute name.
      # @param [ String ] meth The name of the accessor.
      #
      # @since 3.0.0
      def create_dirty_reset(name, meth)
        generated_methods.module_eval do
          re_define_method("reset_#{meth}!") do
            reset_attribute!(name)
          end
        end
      end
    end
  end
end
