# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    class Options #:nodoc:

      # Create the new +Options+ object, which provides convenience methods for
      # accessing values out of an options +Hash+.
      def initialize(attributes = {})
        @attributes = attributes
      end

      # Return the foreign key based off the association name.
      def foreign_key
        name.to_s.foreign_key
      end

      # Returns the name of the inverse_of association
      def inverse_of
        @attributes[:inverse_of]
      end

      # Return a +Class+ for the options. If a class_name was provided, then the
      # constantized class_name will be returned. If not, a constant based on the
      # association name will be returned.
      def klass
        class_name = @attributes[:class_name]
        class_name ? class_name.constantize : name.to_s.classify.constantize
      end

      # Returns the association name of the options.
      def name
        @attributes[:name]
      end

      # Returns the parent foreign key association name.
      def parent_key
        @attributes[:parent_key]
      end

      # Returns whether or not this association is polymorphic.
      def polymorphic
        @attributes[:polymorphic] == true
      end

    end
  end
end
