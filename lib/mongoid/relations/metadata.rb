# encoding: utf-8
module Mongoid
  module Relations

    # The "Grand Poobah" of information about any relation is this class. It
    # contains everything you could ever possible want to know.
    class Metadata < Hash

      delegate :foreign_key_default, :stores_foreign_key?, to: :relation

      # Returns the as option of the relation.
      #
      # @example Get the as option.
      #   metadata.as
      #
      # @return [ true, false ] The as option.
      #
      # @since 2.1.0
      def as
        self[:as]
      end

      # Tells whether an as option exists.
      #
      # @example Is the as option set?
      #   metadata.as?
      #
      # @return [ true, false ] True if an as exists, false if not.
      #
      # @since 2.0.0.rc.1
      def as?
        !!as
      end

      # Is the relation autobuilding if accessed via the getter and the
      # document is new.
      #
      # @example Is the relation autobuilding?
      #   metadata.autobuilding?
      #
      # @return [ true, false ] If the relation autobuilds.
      #
      # @since 3.0.0
      def autobuilding?
        !!self[:autobuild]
      end

      # Returns the autosave option of the relation.
      #
      # @example Get the autosave option.
      #   metadata.autosave
      #
      # @return [ true, false ] The autosave option.
      #
      # @since 2.1.0
      def autosave
        self[:autosave]
      end

      # Does the metadata have a autosave option?
      #
      # @example Is the relation autosaving?
      #   metadata.autosave?
      #
      # @return [ true, false ] If the relation autosaves.
      #
      # @since 2.1.0
      def autosave?
        !!autosave
      end

      # Gets a relation builder associated with the relation this metadata is
      # for.
      #
      # @example Get the builder.
      #   metadata.builder(document)
      #
      # @param [ Document ] base The base document.
      # @param [ Object ] object A document or attributes to give the builder.
      #
      # @return [ Builder ] The builder for the relation.
      #
      # @since 2.0.0.rc.1
      def builder(base, object)
        relation.builder(base, self, object)
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
          "Mongoid::Relations::Cascading::#{dependent.to_s.classify}".constantize
        end
      end

      # Is this an embedded relations that allows callbacks to cascade down to
      # it?
      #
      # @example Does the relation have cascading callbacks?
      #   metadata.cascading_callbacks?
      #
      # @return [ true, false ] If the relation cascades callbacks.
      #
      # @since 2.3.0
      def cascading_callbacks?
        !!self[:cascade_callbacks]
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
        @class_name ||= (self[:class_name] || classify).sub(/\A::/,"")
      end

      # Get the foreign key contraint for the metadata.
      #
      # @example Get the constaint.
      #   metadata.constraint
      #
      # @return [ Constraint ] The constraint.
      #
      # @since 2.0.0.rc.1
      def constraint
        @constraint ||= Constraint.new(self)
      end

      # Does the metadata have a counter cache?
      #
      # @example Is the metadata counter_cached?
      #   metadata.counter_cached?
      #
      # @return [ true, false ] If the metadata has counter_cache
      #
      # @since 3.1.0
      def counter_cached?
        !!self[:counter_cache]
      end

      # Returns the counter cache column name
      #
      # @example Get the counter cache column.
      #   metadata.counter_cache_column_name
      #
      # @return [ String ] The counter cache column
      #
      # @since 3.1.0
      def counter_cache_column_name
        if self[:counter_cache] == true
          "#{inverse_class_name.demodulize.underscore.pluralize}_count"
        else
          self[:counter_cache].to_s
        end
      end

      # Get the criteria that is used to query for this metadata's relation.
      #
      # @example Get the criteria.
      #   metadata.criteria([ id_one, id_two ], Person)
      #
      # @param [ Object ] object The foreign key used for the query.
      # @param [ Class ] type The base class.
      #
      # @return [ Criteria ] The criteria.
      #
      # @since 2.1.0
      def criteria(object, type)
        relation.criteria(self, object, type)
      end

      # Returns the cyclic option of the relation.
      #
      # @example Get the cyclic option.
      #   metadata.cyclic
      #
      # @return [ true, false ] The cyclic option.
      #
      # @since 2.1.0
      def cyclic
        self[:cyclic]
      end

      # Does the metadata have a cyclic option?
      #
      # @example Is the metadata cyclic?
      #   metadata.cyclic?
      #
      # @return [ true, false ] If the metadata is cyclic.
      #
      # @since 2.1.0
      def cyclic?
        !!cyclic
      end

      # Returns the dependent option of the relation.
      #
      # @example Get the dependent option.
      #   metadata.dependent
      #
      # @return [ Symbol ] The dependent option.
      #
      # @since 2.1.0
      def dependent
        self[:dependent]
      end

      # Does the metadata have a dependent option?
      #
      # @example Is the metadata performing cascades?
      #   metadata.dependent?
      #
      # @return [ true, false ] If the metadata cascades.
      #
      # @since 2.1.0
      def dependent?
        !!dependent
      end

      # Get the criteria needed to eager load this relation.
      #
      # @example Get the eager loading criteria.
      #   metadata.eager_load(criteria)
      #
      # @param [ Array<Object> ] ids The ids of the returned parents.
      #
      # @return [ Criteria ] The eager loading criteria.
      #
      # @since 2.2.0
      def eager_load(ids)
        relation.eager_load(self, ids)
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

      # Returns the extension of the relation.
      #
      # @example Get the relation extension.
      #   metadata.extension
      #
      # @return [ Module ] The extension or nil.
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

      # Does this metadata have a forced nil inverse_of defined. (Used in many
      # to manies)
      #
      # @example Is this a forced nil inverse?
      #   metadata.forced_nil_inverse?
      #
      # @return [ true, false ] If inverse_of has been explicitly set to nil.
      #
      # @since 2.3.3
      def forced_nil_inverse?
        @forced_nil_inverse ||= has_key?(:inverse_of) && inverse_of.nil?
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

      # Get the name of the method to check if the foreign key has changed.
      #
      # @example Get the foreign key check method.
      #   metadata.foreign_key_check
      #
      # @return [ String ] The foreign key check.
      #
      # @since 2.1.0
      def foreign_key_check
        @foreign_key_check ||= "#{foreign_key}_changed?"
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

      # Returns the index option of the relation.
      #
      # @example Get the index option.
      #   metadata.index
      #
      # @return [ true, false ] The index option.
      #
      # @since 2.1.0
      def index
        self[:index]
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
        !!index
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
        Options.validate!(properties)
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
%Q{#<Mongoid::Relations::Metadata
  autobuild:    #{autobuilding?}
  class_name:   #{class_name}
  cyclic:       #{cyclic.inspect}
  counter_cache:#{counter_cached?}
  dependent:    #{dependent.inspect}
  inverse_of:   #{inverse_of.inspect}
  key:          #{key}
  macro:        #{macro}
  name:         #{name}
  order:        #{order.inspect}
  polymorphic:  #{polymorphic?}
  relation:     #{relation}
  setter:       #{setter}
  versioned:    #{versioned?}>
}
      end

      # Get the name of the inverse relations if they exists. If this is a
      # polymorphic relation then just return the :as option that was defined.
      #
      # @example Get the names of the inverses.
      #   metadata.inverses
      #
      # @param [ Document ] other The document to aid in the discovery.
      #
      # @return [ Array<Symbol> ] The inverse name.
      def inverses(other = nil)
        if self[:polymorphic]
          lookup_inverses(other)
        else
          @inverses ||= determine_inverses
        end
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
        invs = inverses(other)
        invs.first if invs.count == 1
      end

      # Returns the inverse_class_name option of the relation.
      #
      # @example Get the inverse_class_name option.
      #   metadata.inverse_class_name
      #
      # @return [ true, false ] The inverse_class_name option.
      #
      # @since 2.1.0
      def inverse_class_name
        self[:inverse_class_name]
      end

      # Returns the if the inverse class name option exists.
      #
      # @example Is an inverse class name defined?
      #   metadata.inverse_class_name?
      #
      # @return [ true, false ] If the inverse if defined.
      #
      # @since 2.1.0
      def inverse_class_name?
        !!inverse_class_name
      end

      # Is the inverse field bindable? Ie, do we have more than one definition
      # on the parent class with the same polymorphic name (as).
      #
      # @example Is the inverse of bindable?
      #   metadata.inverse_of_bindable?
      #
      # @return [ true, false ] If the relation needs the inverse of field set.
      #
      # @since 3.0.6
      def inverse_field_bindable?
        @inverse_field_bindable ||= (inverse_klass.relations.values.count do |meta|
          meta.as == as
        end > 1)
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
        @inverse_foreign_key ||= determine_inverse_foreign_key
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

      # Get the metadata for the inverse relation.
      #
      # @example Get the inverse metadata.
      #   metadata.inverse_metadata(doc)
      #
      # @param [ Document, Class ] object The document or class.
      #
      # @return [ Metadata ] The inverse metadata.
      #
      # @since 2.1.0
      def inverse_metadata(object)
        object.reflect_on_association(inverse(object))
      end

      # Returns the inverse_of option of the relation.
      #
      # @example Get the inverse_of option.
      #   metadata.inverse_of
      #
      # @return [ true, false ] The inverse_of option.
      #
      # @since 2.1.0
      def inverse_of
        self[:inverse_of]
      end

      # Does the metadata have a inverse_of option?
      #
      # @example Is an inverse_of defined?
      #   metadata.inverse_of?
      #
      # @return [ true, false ] If the relation has an inverse_of defined.
      #
      # @since 2.1.0
      def inverse_of?
        !!inverse_of
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
        inverse(other).__setter__
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
        @inverse_type ||= determine_inverse_for(:type)
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
        @inverse_type_setter ||= inverse_type.__setter__
      end

      # Returns the name of the field in which to store the name of the inverse
      # field for the polymorphic relation.
      #
      # @example Get the name of the field.
      #   metadata.inverse_of_field
      #
      # @return [ String ] The name of the field for storing the name of the
      #   inverse field.
      #
      # @since 2.4.5
      def inverse_of_field
        @inverse_of_field ||= determine_inverse_for(:field)
      end

      # Gets the setter for the field that stores the name of the inverse field
      # on a polymorphic relation.
      #
      # @example Get the inverse type setter.
      #   metadata.inverse_of_field_setter
      #
      # @return [ String ] The name of the setter.
      def inverse_of_field_setter
        @inverse_of_field_setter ||= inverse_of_field.__setter__
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

      # Is this metadata representing a one to many or many to many relation?
      #
      # @example Is the relation a many?
      #   metadata.many?
      #
      # @return [ true, false ] If the relation is a many.
      #
      # @since 2.1.6
      def many?
        @many ||= (relation.macro.to_s =~ /many/)
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

      # Get the name associated with this metadata.
      #
      # @example Get the name.
      #   metadata.name
      #
      # @return [ Symbol ] The name.
      #
      # @since 2.1.0
      def name
        self[:name]
      end

      # Is the name defined?
      #
      # @example Is the name defined?
      #   metadata.name?
      #
      # @return [ true, false ] If the name is defined.
      #
      # @since 2.1.0
      def name?
        !!name
      end

      # Does the relation have a destructive dependent option specified. This
      # is true for :dependent => :delete and :dependent => :destroy.
      #
      # @example Is the relation destructive?
      #   metadata.destructive?
      #
      # @return [ true, false ] If the relation is destructive.
      #
      # @since 2.1.0
      def destructive?
        @destructive ||= (dependent == :delete || dependent == :destroy)
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

      # Get the path calculator for the supplied document.
      #
      # @example Get the path calculator.
      #   metadata.path(document)
      #
      # @param [ Document ] document The document to calculate on.
      #
      # @return [ Object ] The atomic path calculator.
      #
      # @since 2.1.0
      def path(document)
        relation.path(document)
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

      # Get the primary key field for finding the related document.
      #
      # @example Get the primary key.
      #   metadata.primary_key
      #
      # @return [ String ] The primary key field.
      #
      # @since 3.1.0
      def primary_key
        @primary_key ||= (self[:primary_key] || "_id").to_s
      end

      # Get the relation associated with this metadata.
      #
      # @example Get the relation.
      #   metadata.relation
      #
      # @return [ Proxy ] The relation proxy class.
      #
      # @since 2.1.0
      def relation
        self[:relation]
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
        @setter ||= "#{name}="
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
      def type
        @type ||= polymorphic? ? "#{as}_type" : nil
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
      def type_setter
        @type_setter ||= type.__setter__
      end


      # Key where embedded document is save.
      # By default is the name of relation
      #
      # @return [ String ] the name of key where save
      #
      # @since 3.0.0
      def store_as
        @store_as ||= (self[:store_as].try(:to_s) || name.to_s)
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
        unless self[:validate].nil?
          self[:validate]
        else
          self[:validate] = relation.validation_default
        end
      end

      # Is this relation using Mongoid's internal versioning system?
      #
      # @example Is this relation versioned?
      #   metadata.versioned?
      #
      # @return [ true, false ] If the relation uses Mongoid versioning.
      #
      # @since 2.1.0
      def versioned?
        !!self[:versioned]
      end

      # Returns the metadata itself. Here for compatibility with Rails
      # association metadata.
      #
      # @example Get the options.
      #   metadata.options
      #
      # @return [ Metadata ] self.
      #
      # @since 2.4.6
      def options
        self
      end

      # Returns default order for this association.
      #
      # @example Get default order
      #   metadata.order
      #
      # @return [ Criterion::Complex, nil] nil if doesn't set
      #
      # @since 2.1.0
      def order
        self[:order]
      end

      # Is a default order set?
      #
      # @example Is the order set?
      #   metadata.order?
      #
      # @return [ true, false ] If the order is set.
      #
      # @since 2.1.0
      def order?
        !!order
      end

      # Is this relation touchable?
      #
      # @example Is the relation touchable?
      #   metadata.touchable?
      #
      # @return [ true, false ] If the relation can be touched.
      #
      # @since 3.0.0
      def touchable?
        !!self[:touch]
      end

      # Returns the metadata class types.
      #
      # @example Get the relation class types.
      #   metadata.type_relation
      #
      # @return [ Hash ] The hash with relation class types.
      #
      # @since 3.1.0
      def type_relation
        { _type: { "$in" => klass._types }}
      end

      private

      # Returns the class name for the relation.
      #
      # @example Get the class name.
      #   metadata.classify
      #
      # @return [ String ] The classified name.
      #
      # @since 2.0.0.rc.1
      def classify
        @classify ||= "#{find_module}::#{name.to_s.classify}"
      end

      # Get the name for the inverse field.
      #
      # @api private
      #
      # @example Get the inverse field name.
      #   metadata.determine_inverse_for(:type)
      #
      # @param [ Symbol ] field The inverse field name.
      #
      # @return [ String ] The name of the field.
      #
      # @since 3.0.0
      def determine_inverse_for(field)
        relation.stores_foreign_key? && polymorphic? ? "#{name}_#{field}" : nil
      end

      # Deterimene the inverses that can be memoized.
      #
      # @api private
      #
      # @example Determin the inverses.
      #   metadata.determine_inverses
      #
      # @return [ Array<Symbol> ] The inverses.
      #
      # @since 3.0.0
      def determine_inverses
        return [ inverse_of ] if has_key?(:inverse_of)
        return [ as ] if has_key?(:as)
        return [ cyclic_inverse ] if self[:cyclic]
        [ inverse_relation ]
      end

      # Find the module the class with the specific name is in.
      # This is done by starting at the inverse_class_name's
      # module and stepping down to see where it is defined.
      #
      # @api private
      #
      # @example Find the module.
      #   metadata.find_module
      #
      # @return [ String ] The module.
      #
      # @since 3.0.0
      def find_module
        if inverse_class_name.present?
          parts = inverse_class_name.split('::')
          modules = parts.size.times.map { |i| parts.first(i).join('::') }.reverse
          find_from_parts(modules)
        end
      end

      # Find the modules from a reversed list.
      #
      # @api private
      #
      # @example Find the module from the parts.
      #   metadata.find_from_parts([ "Namespace", "Module" ])
      #
      # @param [ Array<String> ] The modules.
      #
      # @return [ String ] The matching module.
      #
      # @since 3.0.0
      def find_from_parts(modules)
        modules.find do |mod|
          ActiveSupport::Inflector.constantize(mod).constants.include?(
            name.to_s.classify.to_sym
          )
        end
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
        underscored = class_name.demodulize.underscore
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
          relation.foreign_key(name)
        else
          if polymorphic?
            "#{self[:as]}#{suffix}"
          else
            inverse_of ? "#{inverse_of}#{suffix}" : inverse_class_name.foreign_key
          end
        end
      end

      # Determine the inverse foreign key of the relation.
      #
      # @example Determine the inverse foreign key.
      #   metadata.determine_inverse_foreign_key
      #
      # @return [ String ] The inverse.
      #
      # @since 2.3.2
      def determine_inverse_foreign_key
        if has_key?(:inverse_of)
          inverse_of ? "#{inverse_of.to_s.singularize}#{relation.foreign_key_suffix}" : nil
        else
          "#{inverse_class_name.demodulize.underscore}#{relation.foreign_key_suffix}"
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
        default = foreign_key_match || klass.relations[inverse_klass.name.underscore]
        return default.name if default
        names = inverse_relation_candidate_names
        if names.size > 1
          raise Errors::AmbiguousRelationship.new(klass, inverse_klass, name, names)
        end
        names.first
      end

      # Return metadata where the foreign key matches the foreign key on this
      # relation.
      #
      # @api private
      #
      # @example Return a foreign key match.
      #   meta.foreign_key_match
      #
      # @return [ Metadata ] A match, if any.
      #
      # @since 2.4.11
      def foreign_key_match
        if fk = self[:foreign_key]
          relations_metadata.detect do |meta|
            fk == meta.foreign_key if meta.stores_foreign_key?
          end
        end
      end

      # Get the inverse relation candidates.
      #
      # @api private
      #
      # @example Get the inverse relation candidates.
      #   metadata.inverse_relation_candidates
      #
      # @return [ Array<Metdata> ] The candidates.
      #
      # @since 3.0.0
      def inverse_relation_candidates
        relations_metadata.select do |meta|
          next if meta.versioned? || meta.name == name
          meta.class_name == inverse_class_name
        end
      end

      # Get the candidates for inverse relations.
      #
      # @api private
      #
      # @example Get the candidates.
      #   metadata.inverse_relation_candidates
      #
      # @return [ Array<Symbol> ] The candidates.
      #
      # @since 3.0.0
      def inverse_relation_candidate_names
        @candidate_names ||= inverse_relation_candidates.map(&:name)
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
        return store_as.to_s if relation.embedded?
        relation.stores_foreign_key? ? foreign_key : primary_key
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
      # @example Find the inverses.
      #   metadata.lookup_inverses(other)
      #
      # @param [ Document ] : The inverse document.
      #
      # @return [ Array<String> ] The inverse names.
      def lookup_inverses(other)
        return [ inverse_of ] if inverse_of
        if other
          matches = []
          other.class.relations.values.each do |meta|
            if meta.as == name && meta.class_name == inverse_class_name
              matches.push(meta.name)
            end
          end
          matches
        end
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
        if invs = lookup_inverses(other) && invs.count == 1
          invs.first
        end
      end

      # Get the relation metadata only.
      #
      # @api private
      #
      # @example Get the relation metadata.
      #   metadata.relations_metadata
      #
      # @return [ Array<Metadata> ] The metadata.
      #
      # @since 3.0.0
      def relations_metadata
        klass.relations.values
      end
    end
  end
end
