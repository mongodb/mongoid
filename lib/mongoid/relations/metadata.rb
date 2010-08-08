# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    class Metadata < Hash #:nodoc:

      # Returns the name of the class that this relation contains. If the
      # class_name was provided as an option this will return that, otherwise
      # it will determine the name from the name property.
      #
      # Example:
      #
      # <tt>metadata.class_name</tt>
      #
      # Returns:
      #
      # A +String+ name of the relation's proxied class.
      def class_name
        self[:class_name] || name.to_s.classify
      end

      # Returns the extension of the relation. This can be a +Proc+
      # or +Module+.
      #
      # Example:
      #
      # <tt>metadata.extension</tt>
      #
      # Returns:
      #
      # The extension or nil.
      def extension
        self[:extend]
      end

      # Tells whether an extension definition exist for this relation.
      #
      # Example:
      #
      # <tt>metadata.extension?</tt>
      #
      # Returns:
      #
      # True if an extension exists, false if not.
      def extension?
        !!extension
      end

      # Tells whether a foreign key index exists on the relation.
      #
      # Example:
      #
      # <tt>metadata.indexed?</tt>
      #
      # Returns:
      #
      # True if an index exists, false if not.
      def indexed?
        !!self[:index]
      end

      # Instantiate new metadata for a relation.
      #
      # Example:
      #
      # <tt>Metadata.new(:name => :addresses)</tt>
      #
      # Options:
      #
      # properties: A +Hash+ of relation properties.
      def initialize(properties = {})
        merge!(properties)
      end

      # Returns the inverse class of the proxied relation.
      #
      # Example:
      #
      # <tt>metadata.inverse_klass</tt>
      #
      # Returns:
      #
      # The +Class+ of the inverse of the relation.
      def inverse_klass
        @inverse_klass ||= inverse_class_name.constantize
      end

      # Returns the class of the proxied relation.
      #
      # Example:
      #
      # <tt>metadata.klass</tt>
      #
      # Returns:
      #
      # The +Class+ of the relation.
      def klass
        @klass ||= class_name.constantize
      end

      # Returns the macro for the relation of this metadata.
      #
      # Example:
      #
      # <tt>metadata.macro</tt>
      #
      # Returns:
      #
      # The macro as a +Symbol+.
      def macro
        relation.macro
      end

      private

      # Handles two different cases - the first is a convenience for JSON like
      # access to the hash instead of having to call []. The second is a
      # delegation of the "*?" methods to has_key? as a convenience to check
      # for existence of a value.
      #
      # Example:
      #
      # <tt>metadata.name</tt>
      # <tt>metadata.name?</tt>
      #
      # Returns:
      #
      # Either the value or a boolen.
      def method_missing(name, *args)
        method = name.to_s
        if method.include?('?')
          has_key?(method.sub('?', '').to_sym)
        else
          self[name]
        end
      end
    end
  end
end
