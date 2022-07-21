# frozen_string_literal: true

require 'mongoid/association/referenced/belongs_to/binding'
require 'mongoid/association/referenced/belongs_to/buildable'
require 'mongoid/association/referenced/belongs_to/proxy'
require 'mongoid/association/referenced/belongs_to/eager'

module Mongoid
  module Association
    module Referenced

      # The BelongsTo type association.
      class BelongsTo
        include Relatable
        include Buildable

        # The options available for this type of association, in addition to the
        # common ones.
        #
        # @return [ Array<Symbol> ] The extra valid options.
        ASSOCIATION_OPTIONS = [
            :autobuild,
            :autosave,
            :counter_cache,
            :dependent,
            :foreign_key,
            :index,
            :polymorphic,
            :primary_key,
            :touch,
            :optional,
            :required,
            :scope,
        ].freeze

        # The complete list of valid options for this association, including
        # the shared ones.
        #
        # @return [ Array<Symbol> ] The valid options.
        VALID_OPTIONS = (ASSOCIATION_OPTIONS + SHARED_OPTIONS).freeze

        # The type of the field holding the foreign key.
        #
        # @return [ Object ]
        FOREIGN_KEY_FIELD_TYPE = Object

        # The default foreign key suffix.
        #
        # @return [ String ] '_id'
        FOREIGN_KEY_SUFFIX = '_id'.freeze

        # The list of association complements.
        #
        # @return [ Array<Association> ] The association complements.
        def relation_complements
          @relation_complements ||= [ HasMany, HasOne ].freeze
        end

        # Setup the instance methods, fields, etc. on the association owning class.
        #
        # @return [ self ]
        def setup!
          setup_instance_methods!
          @owner_class.aliased_fields[name.to_s] = foreign_key
          self
        end

        # Does this association type store the foreign key?
        #
        # @return [ true ] Always true.
        def stores_foreign_key?; true; end

        # Is this association type embedded?
        #
        # @return [ false ] Always false.
        def embedded?; false; end

        # The default for validation the association object.
        #
        # @return [ false ] Always false.
        def validation_default; false; end

        # Get the foreign key field for saving the association reference.
        #
        # @return [ String ] The foreign key field for saving the association reference.
        def foreign_key
          @foreign_key ||= @options[:foreign_key] ? @options[:foreign_key].to_s :
                             default_foreign_key_field
        end

        # Get the association proxy class for this association type.
        #
        # @return [ Association::BelongsTo::Proxy ] The proxy class.
        def relation
          Proxy
        end

        # Is this association polymorphic?
        #
        # @return [ true | false ] Whether this association is polymorphic.
        def polymorphic?
          @polymorphic ||= !!@options[:polymorphic]
        end

        # The name of the field used to store the type of polymorphic association.
        #
        # @return [ String ] The field used to store the type of polymorphic association.
        def inverse_type
          (@inverse_type ||= "#{name}_type") if polymorphic?
        end

        # The nested builder object.
        #
        # @param [ Hash ] attributes The attributes to use to build the association object.
        # @param [ Hash ] options The options for the association.
        #
        # @return [ Association::Nested::One ] The Nested Builder object.
        def nested_builder(attributes, options)
          Nested::One.new(self, attributes, options)
        end

        # Get the path calculator for the supplied document.
        #
        # @example Get the path calculator.
        #   association.path(document)
        #
        # @param [ Document ] document The document to calculate on.
        #
        # @return [ Root ] The root atomic path calculator.
        def path(document)
          Mongoid::Atomic::Paths::Root.new(document)
        end

        # Get the scope to be applied when querying the association.
        #
        # @return [ Proc | Symbol | nil ] The association scope, if any.
        def scope
          @options[:scope]
        end

        private

        def setup_instance_methods!
          define_getter!
          define_setter!
          define_existence_check!
          define_builder!
          define_creator!
          define_autosaver!
          define_counter_cache_callbacks!
          polymorph!
          define_dependency!
          create_foreign_key_field!
          setup_index!
          define_touchable!
          @owner_class.validates_associated(name) if validate? || require_association?
          @owner_class.validates(name, presence: true) if require_association?
        end

        def index_spec
          if polymorphic?
            { key => 1, inverse_type => 1 }
          else
            { key => 1 }
          end
        end

        def default_primary_key
          PRIMARY_KEY_DEFAULT
        end

        def default_foreign_key_field
          @default_foreign_key_field ||= "#{name}#{FOREIGN_KEY_SUFFIX}"
        end

        def polymorph!
          if polymorphic?
            @owner_class.polymorphic = true
            @owner_class.field(inverse_type, type: String)
          end
        end

        def polymorphic_inverses(other = nil)
          if other
            matches = other.relations.values.select do |rel|
              relation_complements.include?(rel.class) &&
                  rel.as == name &&
                  rel.relation_class_name == inverse_class_name
            end
            matches.collect { |m| m.name }
          end
        end

        def determine_inverses(other)
          matches = (other || relation_class).relations.values.select do |rel|
            relation_complements.include?(rel.class) &&
                rel.relation_class_name == inverse_class_name

          end
          if matches.size > 1
            raise Errors::AmbiguousRelationship.new(relation_class, @owner_class, name, matches)
          end
          matches.collect { |m| m.name }
        end

        # If set to true, then the associated object will be validated when this object is saved
        def require_association?
          required = @options[:required] if @options.key?(:required)
          required = !@options[:optional] if @options.key?(:optional) && required.nil?
          required.nil? ? Mongoid.belongs_to_required_by_default : required
        end

        def create_foreign_key_field!
          @owner_class.field(
              foreign_key,
              type: FOREIGN_KEY_FIELD_TYPE,
              identity: true,
              overwrite: true,
              association: self,
              default: nil
          )
        end
      end
    end
  end
end
