# frozen_string_literal: true

require 'mongoid/association/constrainable'
require 'mongoid/association/options'

module Mongoid
  module Association

    # This module provides behaviors shared between Association types.
    module Relatable
      include Constrainable
      include Options

      # The options shared between all association types.
      #
      # @return [ Array<Symbol> ] The shared options.
      SHARED_OPTIONS = [
                         :class_name,
                         :inverse_of,
                         :validate,
                         :extend
                       ].freeze

      # The primary key default.
      #
      # @return [ String ] The primary key field default.
      PRIMARY_KEY_DEFAULT = '_id'.freeze

      # The name of the association.
      #
      # @return [ Symbol ] The name of the association.
      attr_reader :name

      # The options on this association.
      #
      # @return [ Hash ] The options.
      attr_reader :options

      # Initialize the Association.
      #
      # @param [ Class ] _class The class of the model who owns this association.
      # @param [ Symbol ] name The name of the association.
      # @param [ Hash ] opts The association options.
      # @param [ Block ] block The optional block.
      def initialize(_class, name, opts = {}, &block)
        @owner_class = _class
        @name = name
        @options = opts
        @extension = nil

        @module_path = _class.name ? _class.name.split('::')[0..-2].join('::') : ''
        @module_path << '::' unless @module_path.empty?

        create_extension!(&block)
        validate!
      end

      # Compare this association to another.
      #
      # @return [ Object ] The object to compare to this association.
      def ==(other)
        relation_class_name == other.relation_class_name &&
          inverse_class_name == other.inverse_class_name &&
            name == other.name &&
              options == other.options
      end

      # Get the callbacks for a given type.
      #
      # @param [ Symbol ] callback_type The type of callback type.
      #
      # @return [ Array<Proc | Symbol> ] A list of the callbacks, either method
      #   names or Procs.
      def get_callbacks(callback_type)
        Array(options[callback_type])
      end

      # Get the type setter.
      # @note Only relevant for polymorphic associations that take the :as option.
      #
      # @return [ String ] The type setter method.
      def type_setter
        @type_setter ||= type.__setter__
      end

      # Whether trying to bind an object using this association should raise
      # an error.
      #
      # @param [ Document ] doc The document to be bound.
      #
      # @return [ true | false ] Whether the document can be bound.
      def bindable?(doc); false; end

      # Get the inverse names.
      #
      # @param [ Object ] other The other model class or model object to use when
      #   determining inverses.
      #
      # @return [ Array<Symbol> ] The list of inverse names.
      def inverses(other = nil)
        return [ inverse_of ] if inverse_of
        return [] if @options.key?(:inverse_of) && !inverse_of

        if polymorphic?
          polymorphic_inverses(other)
        else
          determine_inverses(other)
        end
      end

      # Get the inverse's association metadata.
      #
      # @param [ Object ] other The other model class or model object to use when
      #   determining inverses.
      #
      # @return [ Association ] The inverse's association metadata.
      def inverse_association(other = nil)
        (other || relation_class).relations[inverse(other)]
      end

      # Get the inverse type.
      #
      # @return [ nil ] Default is nil for an association.
      def inverse_type; end

      # The class name, possibly unqualified or :: prefixed, of the association
      # object(s).
      #
      # This method returns the class name as it is used in the association
      # definition. If :class_name option is given in the association, the
      # exact value of that option is returned here. If :class_name option is
      # not given, the name of the class is calculated from association name
      # but is not resolved to the actual class.
      #
      # The class name returned by this method may not correspond to a defined
      # class, either because the corresponding class has not been loaded yet,
      # or because the association references a non-existent class altogether.
      # To obtain the association class, use +relation_class+ method.
      #
      # @note The return value of this method should not be used to determine
      #   whether two associations have the same target class, because the
      #   return value is not always a fully qualified class name. To compare
      #   classes, retrieve the class instance of the association target using
      #   the +relation_class+ method.
      #
      # @return [ String ] The association objects' class name.
      def relation_class_name
        @class_name ||= @options[:class_name] || ActiveSupport::Inflector.classify(name)
      end
      alias :class_name :relation_class_name

      # The class of the association object(s).
      #
      # This method returns the class instance corresponding to
      # +relation_class_name+, resolved relative to the host document class.
      #
      # If the class does not exist, this method raises NameError. This can
      # happen because the target class has not yet been defined. Note that
      # polymorphic associations generally do not have a well defined target
      # class because the target class can change from one object to another,
      # and calling this method on a polymorphic association will generally
      # fail with a NameError or produce misleading results (if a class does
      # happen to be defined with the same name as the association name).
      #
      # @return [ String ] The association objects' class.
      def relation_class
        @klass ||= begin
          cls_name = @options[:class_name] || ActiveSupport::Inflector.classify(name)
          resolve_name(inverse_class, cls_name)
        end
      end
      alias :klass :relation_class

      # The class name of the object owning this association.
      #
      # @return [ String ] The owning objects' class name.
      def inverse_class_name
        @inverse_class_name ||= @owner_class.name
      end

      # The class of the object owning this association.
      #
      # @return [ String ] The owning objects' class.
      def inverse_class
        @owner_class
      end
      alias :inverse_klass :inverse_class

      # The foreign key field if this association stores a foreign key.
      # Otherwise, the primary key.
      #
      # @return [ Symbol | String ] The primary key.
      def key
        stores_foreign_key? ? foreign_key : primary_key
      end

      # The name of the setter on this object for assigning an associated object.
      #
      # @return [ String ] The setter name.
      def setter
        @setter ||= "#{name}="
      end

      # The name of the inverse setter method.
      #
      # @return [ String ] The name of the inverse setter.
      def inverse_setter(other = nil)
        @inverse_setter ||= "#{inverses(other).first}=" unless inverses(other).blank?
      end

      # The name of the foreign key setter method.
      #
      # @return [ String ] The name of the foreign key setter.
      def foreign_key_setter
        # note: You can't check if this association stores foreign key
        # See HasOne and HasMany binding, they referenced foreign_key_setter
        @foreign_key_setter ||= "#{foreign_key}=" if foreign_key
      end

      # The atomic path for this association.
      #
      # @return [  Mongoid::Atomic::Paths::Root ] The atomic path object.
      def path(document)
        relation.path(document)
      end

      # Gets the setter for the field that sets the type of document on a
      # polymorphic association.
      #
      # @example Get the inverse type setter.
      #   association.inverse_type_setter
      #
      # @return [ String ] The name of the setter.
      def inverse_type_setter
        @inverse_type_setter ||= inverse_type.__setter__
      end

      # Get the name of the method to check if the foreign key has changed.
      #
      # @example Get the foreign key check method.
      #   association.foreign_key_check
      #
      # @return [ String ] The foreign key check.
      def foreign_key_check
        @foreign_key_check ||= "#{foreign_key}_previously_changed?" if (stores_foreign_key? && foreign_key)
      end

      # Create an association proxy object using the owner and target.
      #
      # @param [ Document ] owner The document this association hangs off of.
      # @param [ Document | Array<Document> ] target The target (parent) of the
      #   association.
      #
      # @return [ Proxy ]
      def create_relation(owner, target)
        relation.new(owner, target, self)
      end

      # Whether the dependent method is destructive.
      #
      # @return [ true | false ] If the dependent method is destructive.
      def destructive?
        @destructive ||= !!(dependent && (dependent == :delete_all || dependent == :destroy))
      end

      # Get the counter cache column name.
      #
      # @return [ String ] The counter cache column name.
      def counter_cache_column_name
        @counter_cache_column_name ||= (@options[:counter_cache].is_a?(String) ||
            @options[:counter_cache].is_a?(Symbol)) ?
            @options[:counter_cache] : "#{inverse || inverse_class_name.demodulize.underscore.pluralize}_count"
      end

      # Get the extension.
      #
      # @return [ Module ] The extension module, if one has been defined.
      def extension
        @extension ||= @options[:extend]
      end

      # Get the inverse name.
      #
      # @return [ Symbol ] The inverse name.
      def inverse(other = nil)
        candidates = inverses(other)
        candidates.detect { |c| c } if candidates
      end

      # Whether the associated object(s) should be validated.
      #
      # @return [ true | false ] If the associated object(s)
      #   should be validated.
      def validate?
        @validate ||= if @options[:validate].nil?
                        validation_default
                      else
                        !!@options[:validate]
                      end
      end

      # @return [ Array<String> ] The associations above this one in the inclusion tree.
      attr_accessor :parent_inclusions

      def parent_inclusions
        @parent_inclusions ||= []
      end

      # Is this association an embeds_many or has_many association?
      #
      # @return [ true | false ] true if it is a *_many association, false if not.
      def many?
        [Referenced::HasMany, Embedded::EmbedsMany].any? { |a| self.is_a?(a) }
      end

      # Is this association an embeds_one or has_one association?
      #
      # @return [ true | false ] true if it is a *_one association, false if not.
      def one?
        [Referenced::HasOne, Embedded::EmbedsOne].any? { |a| self.is_a?(a) }
      end

      # Is this association an embedded_in or belongs_to association?
      #
      # @return [ true | false ] true if it is an embedded_in or belongs_to
      #   association, false if not.
      def in_to?
        [Referenced::BelongsTo, Embedded::EmbeddedIn].any? { |a| self.is_a?(a) }
      end

      private

      # Gets the model classes with inverse associations of this model. This is used to determine
      # the classes on the other end of polymorphic associations with models.
      def inverse_association_classes
        Mongoid::Config.models.map { |m| inverse_association(m) }.compact.map(&:inverse_class)
      end

      def setup_index!
        @owner_class.index(index_spec, background: true) if indexed?
      end

      def define_touchable!
        if touchable?
          Touchable.define_touchable!(self)
        end
      end

      def define_autosaver!
        if autosave?
          Association::Referenced::AutoSave.define_autosave!(self)
        end
      end

      def define_builder!
        Association::Builders.define_builder!(self)
      end

      def define_creator!
        Association::Builders.define_creator!(self)
      end

      def define_getter!
        Association::Accessors.define_getter!(self)
      end

      def define_setter!
        Association::Accessors.define_setter!(self)
      end

      def define_existence_check!
        Association::Accessors.define_existence_check!(self)
      end

      def define_ids_getter!
        Association::Accessors.define_ids_getter!(self)
      end

      def define_ids_setter!
        Association::Accessors.define_ids_setter!(self)
      end

      def define_counter_cache_callbacks!
        if counter_cached?
          Association::Referenced::CounterCache.define_callbacks!(self)
        end
      end

      def define_dependency!
        if dependent
          Association::Depending.define_dependency!(self)
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

      # Returns an array of classes/modules forming the namespace hierarchy
      # where symbols referenced in the provided class/module would be looked
      # up by Ruby. For example, if mod is Foo::Bar, this method would return
      # [Foo::Bar, Foo, Object].
      def namespace_hierarchy(mod)
        parent = Object
        hier = [parent]

        # name is not present on anonymous modules
        if mod.name
          mod.name.split('::').each do |part|
            parent = parent.const_get(part)
            hier << parent
          end
        end

        hier.reverse
      end

      # Resolves the given class/module name in the context of the specified
      # module, as Ruby would when a constant is referenced in the source.
      #
      # @note This method can swallow exceptions produced during class loading,
      #   because it rescues NameError internally. Since this method attempts
      #   to load classes, failure during the loading process may also lead to
      #   there being incomplete class definitions.
      def resolve_name(mod, name)
        cls = exc = nil
        parts = name.to_s.split('::')
        if parts.first == ''
          parts.shift
          hierarchy = [Object]
        else
          hierarchy = namespace_hierarchy(mod)
        end
        hierarchy.each do |ns|
          begin
            parts.each do |part|
              # Simple const_get sometimes pulls names out of weird scopes,
              # perhaps confusing the receiver (ns in this case) with the
              # local scope. Walk the class hierarchy ourselves one node
              # at a time by specifying false as the second argument.
              ns = ns.const_get(part, false)
            end
            cls = ns
            break
          rescue NameError => e
            if exc.nil?
              exc = e
            end
          end
        end
        if cls.nil?
          # Raise the first exception, this is from the most specific namespace
          raise exc
        end
        cls
      end
    end
  end
end
