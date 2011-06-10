# encoding: utf-8
module Mongoid #:nodoc:
  module Dirty #:nodoc:
    extend ActiveSupport::Concern

    # Gets the changes for a specific field.
    #
    # @example Get an attribute change.
    #   person = Person.new(:title => "Sir")
    #   person.title = "Madam"
    #   person.attribute_change("title") # [ "Sir", "Madam" ]
    #
    # @param [ String ] name The attribute to check.
    #
    # @return [ Array ] The old and new values.
    def attribute_change(name)
      modifications[name]
    end

    # Determines if a specific field has chaged.
    #
    # @example Has an attribute changed?
    #   person = Person.new(:title => "Sir")
    #   person.title = "Madam"
    #   person.attribute_changed?("title") # true
    #
    # @param [ String ] name The attribute to check.
    #
    # @return [ true, false ] If the attribute has changed.
    def attribute_changed?(name)
      modifications.include?(name)
    end

    # Gets the old value for a specific field.
    #
    # @example
    #
    #   person = Person.new(:title => "Sir")
    #   person.title = "Madam"
    #   person.attribute_was("title") # "Sir"
    #
    # @param [ String ] name The attribute to check.
    #
    # @return [ Object ] The old field value.
    def attribute_was(name)
      change = modifications[name]
      change ? change[0] : attributes[name]
    end

    # Gets the names of all the fields that have changed in the document.
    #
    # @example Get the changed names.
    #   person = Person.new(:title => "Sir")
    #   person.title = "Madam"
    #   person.changed # returns [ "title" ]
    #
    # @return [ Array ] The changed field names.
    def changed
      modifications.keys
    end

    # Alerts to whether the document has been modified or not.
    #
    # @example Has the document been modified?
    #   person = Person.new(:title => "Sir")
    #   person.title = "Madam"
    #   person.changed? # returns true
    #
    # @return [ true, false ] If the document is changed.
    def changed?
      !modifications.empty?
    end

    # Gets all the modifications that have happened to the object as a +Hash+
    # with the keys being the names of the fields, and the values being an
    # +Array+ with the old value and new value.
    #
    # @example Get all the changes.
    #   person = Person.new(:title => "Sir")
    #   person.title = "Madam"
    #   person.changes # returns { "title" => [ "Sir", "Madam" ] }
    #
    # @return [ Hash ] All changes to the document.
    def changes
      modifications
    end

    # Call this method after save, so the changes can be properly switched.
    #
    # @example Move the changes to previous.
    #   person.move_changes
    def move_changes
      @validated = false
      @previous_modifications = modifications.dup
      @modifications = {}
    end

    # Gets all the new values for each of the changed fields, to be passed to
    # a MongoDB $set modifier.
    #
    # @example Get the setters for the atomic updates.
    #   person = Person.new(:title => "Sir")
    #   person.title = "Madam"
    #   person.setters # returns { "title" => "Madam" }
    #
    # @return [ Hash ] A +Hash+ of atomic setters.
    def setters
      modifications.inject({}) do |sets, (field, changes)|
        key = embedded? ? "#{_position}.#{field}" : field
        sets[key] = changes[1]; sets
      end
    end

    # Gets all the modifications that have happened to the object before the
    # object was saved.
    #
    # @example Get the changes from the last update.
    #   person = Person.new(:title => "Sir")
    #   person.title = "Madam"
    #   person.save!
    #   person.previous_changes # returns { "title" => [ "Sir", "Madam" ] }
    #
    # @return [ Hash ] The changes before the last save.
    def previous_changes
      @previous_modifications
    end

    # Resets a changed field back to its old value.
    #
    # @example Reset the field value.
    #   person = Person.new(:title => "Sir")
    #   person.title = "Madam"
    #   person.reset_attribute!("title")
    #   person.title # "Sir"
    #
    # @param [ String ] name The name of the attribute.
    #
    # @return [ Object ] The old field value.
    def reset_attribute!(name)
      value = attribute_was(name)
      value ? attributes[name] = value : attributes.delete(name)
      modifications.delete(name)
    end

    # Sets up the modifications hash. This occurs just after the document is
    # instantiated.
    #
    # @example Init the modifications hashes.
    #   document.setup_notifications
    def setup_modifications
      @accessed ||= {}
      @modifications ||= {}
      @previous_modifications ||= {}
    end

    # Reset all modifications for the document. This will wipe all the marked
    # changes, but not reset the values.
    #
    # @example Reset all modifications.
    #   document.reset_modifications
    def reset_modifications
      @accessed = {}
      @modifications = {}
    end

    protected

    # Audit the original value for a field that can be modified in place.
    #
    # @example Set a value as being accessed.
    #   person.accessed("aliases", [ "007" ])
    #
    # @param [ String ] name The name of the field.
    # @param [ Object ] value The new value.
    #
    # @return [ Object ] The new value.
    def accessed(name, value)
      return value unless value.is_a?(Enumerable)
      @accessed ||= {}
      @accessed[name] = value.dup unless @accessed.has_key?(name)
      value
    end

    # Get all normal modifications plus in place potential changes.
    #
    # @example Get all the modiciations.
    #   person.modifications
    #
    # @return [ Hash ] All changes to the document.
    def modifications
      reset_modifications unless @modifications && @accessed
      @accessed.each_pair do |field, value|
        current = attributes[field]
        @modifications[field] = [ value, current ] if current != value
      end
      @accessed.clear
      @modifications
    end

    # Audit the change of a field's value.
    #
    # @example Modify a field.
    #   person.modify("name", "Jack", "John")
    #
    # @param [ String ] name The name of the field.
    # @param [ Object ] old_value The old value.
    # @param [ Object ] new_value The new value.
    def modify(name, old_value, new_value)
      attributes[name] = new_value
      if @modifications && (old_value != new_value)
        original = @modifications[name].first if @modifications[name]
        @modifications[name] = [ (original || old_value), new_value ]
      end
    end

    module ClassMethods #:nodoc:

      # Add the dynamic dirty methods. These are custom methods defined on a
      # field by field basis that wrap the dirty attribute methods.
      #
      # @example Create the extra dirty methods.
      #   person = Person.new(:title => "Sir")
      #   person.title = "Madam"
      #   person.title_change # [ "Sir", "Madam" ]
      #   person.title_changed? # true
      #   person.title_was # "Sir"
      #   person.reset_title!
      #
      # @param [ String ] name The name of the attributes.
      def add_dirty_methods(name)
        unless instance_methods.include?("#{name}_change") ||
          instance_methods.include?(:"#{name}_change")
          define_method("#{name}_change") { attribute_change(name) }
        end

        unless instance_methods.include?("#{name}_changed?") ||
          instance_methods.include?(:"#{name}_changed?")
          define_method("#{name}_changed?") { attribute_changed?(name) }
        end

        unless instance_methods.include?("#{name}_was") ||
          instance_methods.include?(:"#{name}_was")
          define_method("#{name}_was") { attribute_was(name) }
        end

        unless instance_methods.include?("reset_#{name}!") ||
          instance_methods.include?(:"reset_#{name}!")
          define_method("reset_#{name}!") { reset_attribute!(name) }
        end
      end
    end
  end
end
