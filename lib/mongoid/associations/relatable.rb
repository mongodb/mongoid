require 'mongoid/associations/constrainable'
require 'mongoid/associations/conversions'
require 'mongoid/associations/options'

module Mongoid
  module Associations
    module Relatable
      include Constrainable
      include Conversions
      include Options

      SHARED_OPTIONS = [
          :class_name,
          :inverse_of,
          :validate,
          :extend
      ].freeze

      # The primary key default.
      #
      # @return [ String ] The primary key field default.
      #
      # @since 7.0
      PRIMARY_KEY_DEFAULT = '_id'.freeze

      # The name of the association.
      #
      # @return [ Symbol ] The name of the relation.
      #
      # @since 7.0
      attr_reader :name

      # The options on this association.
      #
      # @return [ Hash ] The options.
      #
      # @since 7.0
      attr_reader :options

      # Initialize the Association.
      #
      # @param [ Class ] _class The class of the model who owns this relation.
      # @param [ Symbol ] name The name of the association.
      # @param [ Hash ] options The relation options.
      #
      # @since 7.0
      def initialize(_class, name, opts = {}, &block)
        @owner_class = _class
        @name = name
        @options = opts
        @extension = nil
        create_extension!(&block)
        validate!
      end

      def ==(other)
        relation_class_name == other.relation_class_name &&
          inverse_class_name == other.inverse_class_name &&
            name == other.name &&
              options == other.options
      end

      # todo: remove
      def merge!(options)
        @options.merge!(options)
        self
      end

      # todo: remove
      def [](key)
        @options[key]
      end

      def type_setter
        @type_setter ||= type.__setter__
      end

      # def foreign_key_match?(relation)
      #
      #   !relation.stores_foreign_key? || (relation.foreign_key == foreign_key)
      # end

      def bindable?(doc); false; end

      def inverses(other = nil)
        return [ inverse_of ] if inverse_of
        if polymorphic?
          polymorphic_inverses(other)
        else
          determine_inverses(other)
        end
      end

      # Returns the name of a single inverse relation.
      def inverse(other = nil)
        # todo this is a hack, change it
        other.first if other.is_a?(Array)
        candidates = inverses(other)
        # note: you want to find the first item that is not nil
        # this line is here so that I can determine scenario under which candidates is nil
        #binding.pry if candidates && candidates.first.nil?
        candidates.detect { |c| c } if candidates
      end

      def inverse_metadata(other = nil)
        (other || relation_class).relations[inverse(other)]
      end


      # The class name of the relation object(s).
      #
      # @return [ String ] The relation objects' class name.
      #
      # @since 7.0
      def relation_class_name
        @class_name ||= @options[:class_name] || ActiveSupport::Inflector.classify(name)
      end
      alias :class_name :relation_class_name

      # The class of the relation object(s).
      #
      # @return [ String ] The relation objects' class.
      #
      # @since 7.0
      def klass
        @klass ||= relation_class_name.constantize
      end
      alias :relation_class :klass

      # The class name of the object owning this relation.
      #
      # @return [ String ] The owning objects' class name.
      #
      # @since 7.0
      def inverse_class_name
        @inverse_class_name ||= @owner_class.name
      end

      # The class of the object owning this relation.
      #
      # @return [ String ] The owning objects' class.
      #
      # @since 7.0
      def inverse_class
        @owner_class
      end
      alias :inverse_klass :inverse_class


      # The foreign key field if this relations stores a foreign key.
      # Otherwise, the primary key.
      #
      # @return [ Symbol, String ] The primary key.
      #
      # @since 7.0
      def key
        stores_foreign_key? ? foreign_key : primary_key
      end

      # The name of the setter on this object for assigning an associated object.
      #
      # @return [ String ] The setter name.
      #
      # @since 7.0
      def setter
        @setter ||= "#{name}="
      end

      # The name of the inverse setter method.
      #
      # @return [ String ] The name of the inverse setter.
      #
      # @since 7.0
      def inverse_setter(other = nil)
        @inverse_setter ||= "#{inverses(other).first}=" unless inverses(other).blank?
      end

      # The name of the foreign key setter method.
      #
      # @return [ String ] The name of the foreign key setter.
      #
      # @since 7.0
      def foreign_key_setter
        # note: You can't check if this metadata stores foreign key
        # See HasOne and HasMany binding, they referenced foreign_key_setter
        @foreign_key_setter ||= "#{foreign_key}=" if foreign_key
      end

      # The atomic path for this relation.
      #
      # @return [  Mongoid::Atomic::Paths::Root ] The atomic path object.
      #
      # @since 7.0
      def path(document)
        relation.path(document)
      end

      # Gets the setter for the field that sets the type of document on a
      # polymorphic relation.
      #
      # @example Get the inverse type setter.
      #   metadata.inverse_type_setter
      #
      # @return [ String ] The name of the setter.
      #
      # @since 7.0
      def inverse_type_setter
        @inverse_type_setter ||= inverse_type.__setter__
      end

      # Get the name of the method to check if the foreign key has changed.
      #
      # @example Get the foreign key check method.
      #   metadata.foreign_key_check
      #
      # @return [ String ] The foreign key check.
      #
      # @since 7.0
      def foreign_key_check
        @foreign_key_check ||= "#{foreign_key}_changed?" if (stores_foreign_key? && foreign_key)
      end

      # Create a relation proxy object using the owner and target.
      #
      # @param [ Document ] base The document this relation hangs off of.
      # @param [ Document, Array<Document> ] target The target (parent) of the
      #   relation.
      #
      # @return [ Proxy ]
      #
      # @since 7.0
      def create_relation(owner, target)
        relation.new(owner, target, self)
      end

      # Whether the dependent method is destructive.
      #
      # @return [ false ] If the dependent method is destructive.
      #
      # @since 7.0
      def destructive?
        @destructive ||= !!(dependent && (dependent == :delete_all || dependent == :destroy))
      end

      def inverse_type; end

      def counter_cache_column_name
        @counter_cache_column_name ||= (@options[:counter_cache].is_a?(String) ||
            @options[:counter_cache].is_a?(Symbol)) ?
            @options[:counter_cache] : "#{inverse || inverse_class_name.demodulize.underscore.pluralize}_count"
      end

      def extension
        @extension ||= @options[:extend]
      end

      private

      def setup_index!
        @owner_class.index(index_spec, background: true) if indexed?
      end

      def define_touchable!
        if touchable?
          Associations::Touchable.define_touchable!(self)
        end
      end

      def define_autosaver!
        if autosave?
          Associations::Referenced::AutoSave.define_autosave!(self)
        end
      end

      def define_builder!
        Associations::Builders.define_builder!(self)
      end

      def define_creator!
        Associations::Builders.define_creator!(self)
      end

      def define_getter!
        Associations::Accessors.define_getter!(self)
      end

      def define_setter!
        Associations::Accessors.define_setter!(self)
      end

      def define_existence_check!
        Associations::Accessors.define_existence_check!(self)
      end

      def define_ids_getter!
        Associations::Accessors.define_ids_getter!(self)
      end

      def define_ids_setter!
        Associations::Accessors.define_ids_setter!(self)
      end

      def define_counter_cache_callbacks!
        if counter_cached?
          Associations::Referenced::CounterCache.define_callbacks!(self)
        end
      end

      def define_dependency!
        if dependent
          Associations::Depending.define_dependency!(self)
        end
      end

      def validate!
        @options.keys.each do |opt|
          unless self.class::VALID_OPTIONS.include?(opt)
            raise Errors::InvalidRelationOption.new(@owner_class, name, opt, self.class::VALID_OPTIONS)
          end
        end

        [name, "#{name}?".to_sym, "#{name}=".to_sym].each do |n|
          if Mongoid.destructive_fields.include?(n)
            raise Errors::InvalidRelation.new(@owner_class, n)
          end
        end
      end

      def polymorph!
        if polymorphic?
          @owner_class.polymorphic = true
        end
      end

      def create_extension!(&block)
        if block
          extension_module_name = "#{@owner_class.to_s.demodulize}#{name.to_s.camelize}RelationExtension"
          silence_warnings do
            @owner_class.const_set(extension_module_name, Module.new(&block))
          end
          @extension = "#{@owner_class}::#{extension_module_name}".constantize
        end
      end

      def default_inverse
        @default_inverse ||= klass.relations[inverse_klass.name.underscore]
      end

      # If set to true, then the associated object(s) will be validated when the owning object is saved.
      #
      # @return [ true, false ] Whether to validate the associated objects.
      #
      # @since 7.0
      def validate?
        @validate ||= if @options[:validate].nil?
                        validation_default
                      else
                        !!@options[:validate]
                      end
      end
    end
  end
end