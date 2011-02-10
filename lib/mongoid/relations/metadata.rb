# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

    # The "Grand Poobah" of information about any relation is this class. It
    # contains everything you could ever possible want to know.
    class Metadata < Hash

      delegate :foreign_key_default, :stores_foreign_key?, :to => :relation

      # Gets a relation builder associated with the relation this metadata is
      # for.
      #
      # @example Get the builder.
      #   metadata.builder(document)
      #
      # @param [ Object ] object A document or attributes to give the builder.
      #
      # @return [ Builder ] The builder for the relation.
      #
      # @since 2.0.0.rc.1
      def builder(object)
        relation.builder(self, object)
      end

      # Returns the name of the strategy used for handling dependent relations.
      #
      # @example Get the strategy.
      #   metadata.cascade_strategy
      #
      # @return [ Object ] The cascading strategy to use.
      #
      # @since 2.0.0.rc.1
      def cascade_strategy
        if dependent?
          strategy =
            %{Mongoid::Relations::Cascading::#{dependent.to_s.classify}}
          strategy.constantize
        else
          return nil
        end
      end

      # Returns the name of the class that this relation contains. If the
      # class_name was provided as an option this will return that, otherwise
      # it will determine the name from the name property.
      #
      # @example Get the class name.
      #   metadata.class_name
      #
      # @return [ String ] The name of the relation's proxied class.
      #
      # @since 2.0.0.rc.1
      def class_name
        @class_name ||= (self[:class_name] || classify)
      end

      def constraint
        @constraint ||= Constraint.new(self)
      end

      # Will determine if the relation is an embedded one or not. Currently
      # only checks against embeds one and many.
      #
      # @example Is the document embedded.
      #   metadata.embedded?
      #
      # @return [ true, false ] True if embedded, false if not.
      #
      # @since 2.0.0.rc.1
      def embedded?
        @embedded ||= (macro == :embeds_one || macro == :embeds_many)
      end

      # Returns the extension of the relation. This can be a proc or module.
      #
      # @example Get the relation extension.
      #   metadata.extension
      #
      # @return [ Proc ] The extension or nil.
      #
      # @since 2.0.0.rc.1
      def extension
        self[:extend]
      end

      # Tells whether an extension definition exist for this relation.
      #
      # @example Is an extension defined?
      #   metadata.extension?
      #
      # @return [ true, false ] True if an extension exists, false if not.
      #
      # @since 2.0.0.rc.1
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
      # @example Get the foreign key.
      #   metadata.foreign_key
      #
      # @return [ String ] The foreign key for the relation.
      #
      # @since 2.0.0.rc.1
      def foreign_key
        @foreign_key ||= determine_foreign_key
      end

      # Returns the name of the method used to set the foreign key on a
      # document.
      #
      # @example Get the setter for the foreign key.
      #   metadata.foreign_key_setter
      #
      # @return [ String ] The foreign_key plus =.
      #
      # @since 2.0.0.rc.1
      def foreign_key_setter
        @foreign_key_setter ||= "#{foreign_key}="
      end

      # Tells whether a foreign key index exists on the relation.
      #
      # @example Is the key indexed?
      #   metadata.indexed?
      #
      # @return [ true, false ] True if an index exists, false if not.
      #
      # @since 2.0.0.rc.1
      def indexed?
        !!self[:index]
      end

      # Instantiate new metadata for a relation.
      #
      # @example Create the new metadata.
      #   Metadata.new(:name => :addresses)
      #
      # @param [ Hash ] properties The relation options.
      #
      # @since 2.0.0.rc.1
      def initialize(properties = {})
        merge!(properties)
      end

      # Since a lot of the information from the metadata is inferred and not
      # explicitly stored in the hash, the inspection needs to be much more
      # detailed.
      #
      # @example Inspect the metadata.
      #   metadata.inspect
      #
      # @return [ String ] Oodles of information in a nice format.
      #
      # @since 2.0.0.rc.1
      def inspect
        "#<Mongoid::Relations::Metadata\n" <<
        "  class_name:           #{class_name},\n" <<
        "  cyclic:               #{cyclic || "No"},\n" <<
        "  dependent:            #{dependent || "None"},\n" <<
        "  inverse_of:           #{inverse_of || "N/A"},\n" <<
        "  inverse_setter:       #{inverse_setter},\n" <<
        "  inverse_type:         #{inverse_type || "N/A"},\n" <<
        "  inverse_type_setter:  #{inverse_type_setter || "N/A"},\n" <<
        "  key:                  #{key},\n" <<
        "  macro:                #{macro},\n" <<
        "  name:                 #{name},\n" <<
        "  polymorphic:          #{polymorphic? ? "Yes" : "No"},\n" <<
        "  relation:             #{relation},\n" <<
        "  setter:               #{setter}>\n"
      end

      # Get the name of the inverse relation if it exists. If this is a
      # polymorphic relation then just return the :as option that was defined.
      #
      # @example Get the name of the inverse.
      #   metadata.inverse
      #
      # @param [ Document ] other The document to aid in the discovery.
      #
      # @return [ Symbol ] The inverse name.
      #
      # @since 2.0.0.rc.1
      def inverse(other = nil)
        return self[:inverse_of] if inverse_of?
        return self[:as] || lookup_inverse(other) if polymorphic?
        @inverse ||= (cyclic? ? cyclic_inverse : inverse_relation)
      end

      # Used for relational many to many only. This determines the name of the
      # foreign key field on the inverse side of the relation, since in this
      # case there are keys on both sides.
      #
      # @example Find the inverse foreign key
      #   metadata.inverse_foreign_key
      #
      # @return [ String ] The foreign key on the inverse.
      #
      # @since 2.0.0.rc.1
      def inverse_foreign_key
        @inverse_foreign_key ||=
          ( inverse_of ? inverse_of.to_s.singularize : inverse_class_name.underscore ) <<
          relation.foreign_key_suffix
      end

      # Returns the inverse class of the proxied relation.
      #
      # @example Get the inverse class.
      #   metadata.inverse_klass
      #
      # @return [ Class ] The class of the inverse of the relation.
      #
      # @since 2.0.0.rc.1
      def inverse_klass
        @inverse_klass ||= inverse_class_name.constantize
      end

      # Returns the setter for the inverse side of the relation.
      #
      # @example Get the inverse setter.
      #   metadata.inverse_setter
      #
      # @param [ Document ] other A document to aid in the discovery.
      #
      # @return [ String ] The inverse setter name.
      #
      # @since 2.0.0.rc.1
      def inverse_setter(other = nil)
        inverse(other).to_s << "="
      end

      # Returns the name of the field in which to store the name of the class
      # for the polymorphic relation.
      #
      # @example Get the name of the field.
      #   metadata.inverse_type
      #
      # @return [ String ] The name of the field for storing the type.
      #
      # @since 2.0.0.rc.1
      def inverse_type
        if relation.stores_foreign_key? && polymorphic?
          (polymorphic? ? name.to_s : class_name.underscore) << "_type"
        else
          return nil
        end
      end

      # Gets the setter for the field that sets the type of document on a
      # polymorphic relation.
      #
      # @example Get the inverse type setter.
      #   metadata.inverse_type_setter
      #
      # @return [ String ] The name of the setter.
      #
      # @since 2.0.0.rc.1
      def inverse_type_setter
        inverse_type ? inverse_type << "=" : nil
      end

      # This returns the key that is to be used to grab the attributes for the
      # relation or the foreign key or id that a referenced relation will use
      # to query for the object.
      #
      # @example Get the lookup key.
      #   metadata.key
      #
      # @return [ String ] The association name, foreign key name, or _id.
      #
      # @since 2.0.0.rc.1
      def key
        @key ||= determine_key
      end

      # Returns the class of the proxied relation.
      #
      # @example Get the class.
      #   metadata.klass
      #
      # @return [ Class ] The class of the relation.
      #
      # @since 2.0.0.rc.1
      def klass
        @klass ||= class_name.constantize
      end

      # Returns the macro for the relation of this metadata.
      #
      # @example Get the macro.
      #   metadata.macro
      #
      # @return [ Symbol ] The macro.
      #
      # @since 2.0.0.rc.1
      def macro
        relation.macro
      end

      # Gets a relation nested builder associated with the relation this metadata
      # is for. Nested builders are used in conjunction with nested attributes.
      #
      # @example Get the nested builder.
      #   metadata.nested_builder(attributes, options)
      #
      # @param [ Hash ] attributes The attributes to build the relation with.
      # @param [ Hash ] options Options for the nested builder.
      #
      # @return [ NestedBuilder ] The nested builder for the relation.
      #
      # @since 2.0.0.rc.1
      def nested_builder(attributes, options)
        relation.nested_builder(self, attributes, options)
      end

      # Returns true if the relation is polymorphic.
      #
      # @example Is the relation polymorphic?
      #   metadata.polymorphic?
      #
      # @return [ true, false ] True if the relation is polymorphic, false if not.
      #
      # @since 2.0.0.rc.1
      def polymorphic?
        @polymorphic ||= (!!self[:as] || !!self[:polymorphic])
      end

      # Gets the method name used to set this relation.
      #
      # @example Get the setter.
      #   metadata = Metadata.new(:name => :person)
      #   metadata.setter # => "person="
      #
      # @return [ String ] The name plus "=".
      #
      # @since 2.0.0.rc.1
      def setter
        @setter ||= "#{name.to_s}="
      end

      # Are we validating this relation automatically?
      #
      # @example Is automatic validation on?
      #   metadata.validate?
      #
      # @return [ true, false ] True unless explictly set to false.
      #
      # @since 2.0.0.rc.1
      def validate?
        self[:validate] != false
      end

      private

      # Returns the class name for the relation.
      #
      # @example Get the class name.
      #   metadata.classify
      #
      # @return [ String ] If embedded_in, the camelized, else classified.
      #
      # @since 2.0.0.rc.1
      def classify
        macro == :embedded_in ? name.to_s.camelize : name.to_s.classify
      end

      # Get the name of the inverse relation in a cyclic relation.
      #
      # @example Get the cyclic inverse name.
      #
      #   class Role
      #     include Mongoid::Document
      #     embedded_in :parent_role, :cyclic => true
      #     embeds_many :child_roles, :cyclic => true
      #   end
      #
      #   metadata = Metadata.new(:name => :parent_role)
      #   metadata.cyclic_inverse # => "child_roles"
      #
      # @return [ String ] The cyclic inverse name.
      #
      # @since 2.0.0.rc.1
      def cyclic_inverse
        @cyclic_inverse ||= determine_cyclic_inverse
      end

      # Determine the cyclic inverse. Performance improvement with the
      # memoization.
      #
      # @example Determine the inverse.
      #   metadata.determine_cyclic_inverse
      #
      # @return [ String ] The cyclic inverse name.
      #
      # @since 2.0.0.rc.1
      def determine_cyclic_inverse
        underscored = class_name.underscore
        klass.relations.each_pair do |key, meta|
          if key =~ /#{underscored.singularize}|#{underscored.pluralize}/ &&
            meta.relation != relation
            return key.to_sym
          end
        end
      end

      # Determine the value for the relation's foreign key. Performance
      # improvement.
      #
      # @example Determine the foreign key.
      #   metadata.determine_foreign_key
      #
      # @return [ String ] The foreign key.
      #
      # @since 2.0.0.rc.1
      def determine_foreign_key
        return self[:foreign_key].to_s if self[:foreign_key]
        suffix = relation.foreign_key_suffix
        if relation.stores_foreign_key?
          if relation.macro == :references_and_referenced_in_many
            "#{name.to_s.singularize}#{suffix}"
          else
            "#{name}#{suffix}"
          end
        else
          if polymorphic?
            "#{self[:as]}#{suffix}"
          else
            inverse_of ? "#{inverse_of}#{suffix}" : inverse_class_name.foreign_key
          end
        end
      end

      # Determine the inverse relation. Memoizing #inverse_relation and adding
      # this method dropped 5 seconds off the test suite as a performance
      # improvement.
      #
      # @example Determine the inverse.
      #   metadata.determine_inverse_relation
      #
      # @return [ Symbol ] The name of the inverse.
      #
      # @since 2.0.0.rc.1
      def determine_inverse_relation
        klass.relations.each_pair do |key, meta|
          if key == inverse_klass.name.underscore ||
            meta.class_name == inverse_class_name
            return key.to_sym
          end
        end
        return nil
      end

      # Determine the key for the relation in the attributes.
      #
      # @example Get the key.
      #   metadata.determine_key
      #
      # @return [ String ] The key in the attributes.
      #
      # @since 2.0.0.rc.1
      def determine_key
        return name.to_s if relation.embedded?
        relation.stores_foreign_key? ? foreign_key : "_id"
      end

      # Determine the name of the inverse relation.
      #
      # @example Get the inverse name.
      #   metadata.inverse_relation
      #
      # @return [ Symbol ] The name of the inverse relation.
      #
      # @since 2.0.0.rc.1
      def inverse_relation
        @inverse_relation ||= determine_inverse_relation
      end

      # Infer the name of the inverse relation from the class.
      #
      # @example Get the inverse name
      #   metadata.inverse_name
      #
      # @return [ String ] The inverse class name underscored.
      #
      # @since 2.0.0.rc.1
      def inverse_name
        @inverse_name ||= inverse_klass.name.underscore
      end

      # For polymorphic children, we need to figure out the inverse from the
      # actual instance on the other side, since we cannot know the exact class
      # name to infer it from at load time.
      #
      # @example Find the inverse.
      #   metadata.lookup_inverse(other)
      #
      # @param [ Document ] : The inverse document.
      #
      # @return [ String ] The inverse name.
      #
      # @since 2.0.0.rc.1
      def lookup_inverse(other)
        return nil unless other
        other.to_a.first.relations.each_pair do |key, meta|
          return meta.name if meta.as == name
        end
      end

      # Handles two different cases - the first is a convenience for JSON like
      # access to the hash instead of having to call []. The second is a
      # delegation of the "*?" methods to has_key? as a convenience to check
      # for existence of a value.
      #
      # @example Extras provided by this method.
      #   metadata.name
      #   metadata.name?
      #
      # @param [ Symbol ] name The name of the method.
      # @param [ Array ] args The arguments passed to the method.
      #
      # @return [ Object ] Either the value or a boolen.
      #
      # @since 2.0.0.rc.1
      def method_missing(name, *args)
        method = name.to_s
        method =~ /\?/ ? has_key?(method.sub('?', '').to_sym) : self[name]
      end
    end
  end
end
