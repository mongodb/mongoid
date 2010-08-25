# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    class Metadata < Hash #:nodoc:

      # Gets a relation builder associated with the relation this metadata is
      # for.
      #
      # Example:
      #
      # <tt>metadata.builder(document)</tt>
      #
      # Options:
      #
      # object: A document or attributes to pass to the builder.
      #
      # Returns:
      #
      # The builder for the relation.
      def builder(object)
        relation.builder(self, object)
      end

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

      # Handles all the logic for figuring out what the foreign_key is for each
      # relations query. The logic is as follows:
      #
      # 1. If the developer defined a custom key, use that.
      # 2. If the relation stores a foreign key,
      #    use the class_name_id strategy.
      # 3. If the relation does not store the key,
      #    use the inverse_class_name_id strategy.
      #
      # Example:
      #
      # <tt>metadata.foreign_key</tt>
      #
      # Returns:
      #
      # A string to use as the foreign key when querying.
      def foreign_key
        return self[:foreign_key] if self[:foreign_key]
        suffix = relation.foreign_key_suffix
        if relation.stores_foreign_key?
          class_name.underscore << suffix
        else
          inverse_class_name.underscore << suffix
        end
      end

      # Returns the name of the method used to set the foreign key on a
      # document.
      #
      # Example:
      #
      # <tt>metadata.foreign_key_setter</tt>
      #
      # Returns:
      #
      # The foreign_key plus =.
      def foreign_key_setter
        foreign_key << "="
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

      # Get the name of the inverse relation if it exists. If this is a
      # polymorphic relation then just return the :as option that was defined.
      #
      # Example:
      #
      # <tt>metadata.inverse</tt>
      #
      # Returns:
      #
      # The inverse name as a symbol.
      def inverse
        return self[:as] if polymorphic?
        inverse_relation
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

      # Returns the setter for the inverse side of the relation.
      #
      # Example:
      #
      # <tt>metadata.inverse_setter</tt>
      #
      # Returns:
      #
      # A string for the setter method name.
      def inverse_setter
        inverse.to_s << "="
      end

      # This returns the key that is to be used to grab the attributes for the
      # relation or the foreign key or id that a referenced relation will use
      # to query for the object.
      #
      # Example:
      #
      # <tt>metadata.key</tt>
      #
      # Returns:
      #
      # The association name, foreign key name, or _id.
      def key
        return name.to_s if relation.embedded?
        relation.stores_foreign_key? ? foreign_key : "_id"
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

      # Returns true if the relation is polymorphic.
      #
      # Example:
      #
      # <tt>metadata.polymorphic?</tt>
      #
      # Returns:
      #
      # true if the relation is polymorphic, false if not.
      def polymorphic?
        !!self[:as] || !!self[:polymorphic]
      end

      private

      # Determine the name of the inverse relation.
      #
      # Example:
      #
      # <tt>metadata.inverse_relation</tt>
      #
      # Returns:
      #
      # The name of the inverse relation.
      def inverse_relation
        klass.relations.keys.each do |key|
          if key =~ /#{inverse_klass.name.underscore}/
            return key.to_sym
          end
        end
        return inverse_klass.name.underscore.to_sym
      end

      # Infer the name of the inverse relation from the class.
      #
      # Example:
      #
      # <tt>metadata.inverse_name</tt>
      #
      # Returns:
      #
      # The inverse class name underscored.
      def inverse_name
        inverse_klass.name.underscore
      end

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
