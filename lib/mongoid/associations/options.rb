# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    class Options < Hash #:nodoc:

      # Create the new +Options+ object, which provides convenience methods for
      # accessing values out of an options +Hash+.
      def initialize(attributes = {})
        self.merge!(attributes)
      end

      # For relational associations we want to know if we cascade deletes or
      # destroys to associations.
      def dependent
        self[:dependent]
      end

      # Returns the extension if it exists, nil if not.
      def extension
        self[:extend]
      end

      # Returns true is the options have extensions.
      def extension?
        !extension.nil?
      end

      # Return the foreign key if it exists, otherwise inflect it from the
      # associated class name.
      def foreign_key
        key = self[:foreign_key] || klass.name.to_s.foreign_key
        key.to_s
      end

      # Returns whether the foreign key column is indexed.
      def index
        self[:index] || false
      end

      # Returns the name of the inverse_of association
      def inverse_of
        self[:inverse_of]
      end

      # Return a +Class+ for the options. See #class_name
      def klass
        class_name.constantize
      end

      # Return a +String+ representing the associated class_name. If a class_name
      # was provided, then the constantized class_name will be returned. If not,
      # a constant based on the association name will be returned.
      def class_name
        self[:class_name] || name.to_s.classify
      end

      # Returns the association name of the options.
      def name
        self[:name].to_s
      end

      # Returns whether or not this association is polymorphic.
      def polymorphic
        self[:polymorphic] == true
      end

      # Used with references_many to save as array of ids.
      def stored_as
        self[:stored_as]
      end

      # Used with references_many to define a default sorting order
      def default_order
        self[:default_order]
      end
    end
  end
end
