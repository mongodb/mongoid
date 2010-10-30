# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Cyclic #:nodoc:
      extend ActiveSupport::Concern

      module ClassMethods #:nodoc:

        # Create a cyclic embedded relation that creates a tree hierarchy for
        # the document and many embedded child documents.
        #
        # This essentially does the same as:
        #
        #   class Role
        #     include Mongoid::Document
        #     embeds_many :child_roles, :class_name => "Role", :cyclic => true
        #     embedded_in :parent_role, :class_name => "Role", :cyclic => true
        #   end
        #
        # And provides the default nomenclature for accessing a parent document
        # or its children.
        def recursively_embeds_many
          embeds_many child_name, :class_name => self.name, :cyclic => true
          embedded_in parent_name, :class_name => self.name, :cyclic => true
        end

        # Create a cyclic embedded relation that creates a single self
        # referencing relationship for a parent and a single child.
        #
        # This essentially does the same as:
        #
        #   class Role
        #     include Mongoid::Document
        #     embeds_one :child_role, :class_name => "Role", :cyclic => true
        #     embedded_in :parent_role, :class_name => "Role", :cyclic => true
        #   end
        #
        # And provides the default nomenclature for accessing a parent document
        # or its children.
        def recursively_embeds_one
          embeds_one child_name(false), :class_name => self.name, :cyclic => true
          embedded_in parent_name, :class_name => self.name, :cyclic => true
        end

        private

        # Determines the parent name given the class.
        #
        # Example:
        #
        # <tt>Role.parent_name</tt>
        #
        # Returns:
        #
        # "parent_" plus the class name underscored.
        def parent_name
          ("parent_" << self.name.underscore.singularize).to_sym
        end

        # Determines the child name given the class.
        #
        # Example:
        #
        # <tt>Role.child_name</tt>
        #
        # Options:
        #
        # many: Is the a many relation?
        #
        # Returns:
        #
        # "child_" plus the class name underscored in singular or plural form.
        def child_name(many = true)
          ("child_" << self.name.underscore.send(many ? :pluralize : :singularize)).to_sym
        end
      end
    end
  end
end
