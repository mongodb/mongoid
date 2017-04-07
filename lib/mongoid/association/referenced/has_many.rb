require 'mongoid/association/referenced/has_many/binding'
require 'mongoid/association/referenced/has_many/builder'
require 'mongoid/association/referenced/has_many/proxy'
require 'mongoid/association/referenced/has_many/enumerable'
require 'mongoid/association/referenced/has_many/eager'

module Mongoid
  module Association
    module Referenced

      # The has_many association.
      #
      # @since 7.0
      class HasMany
        include Relatable

        # The options available for this type of association, in addition to the
        # common ones.
        #
        # @return [ Array<Symbol> ] The extra valid options.
        #
        # @since 7.0
        ASSOCIATION_OPTIONS = [
            :after_add,
            :after_remove,
            :as,
            :autosave,
            :before_add,
            :before_remove,
            :dependent,
            :foreign_key,
            :order,
            :primary_key
        ].freeze

        # The complete list of valid options for this association, including
        # the shared ones.
        #
        # @return [ Array<Symbol> ] The valid options.
        #
        # @since 7.0
        VALID_OPTIONS = (ASSOCIATION_OPTIONS + SHARED_OPTIONS).freeze

        # The list of association complements.
        #
        # @return [ Array<Association> ] The association complements.
        #
        # @since 7.0
        def relation_complements
          @relation_complements ||= [ Referenced::BelongsTo ].freeze
        end

        # Setup the instance methods, fields, etc. on the association owning class.
        #
        # @return [ self ]
        #
        # @since 7.0
        def setup!
          setup_instance_methods!
          self
        end

        # Setup the instance methods on the class having this association type.
        #
        # @return [ self ]
        #
        # @since 7.0
        def setup_instance_methods!
          define_getter!
          define_ids_getter!
          define_setter!
          define_ids_setter!
          define_existence_check!
          define_autosaver!
          polymorph!
          define_dependency!
          @owner_class.validates_associated(name) if validate?
          self
        end


        # Get the foreign key field on the inverse for saving the association reference.
        #
        # @return [ String ] The foreign key field on the inverse for saving the
        #   association reference.
        #
        # @since 7.0
        def foreign_key
          @foreign_key ||= @options[:foreign_key] ? @options[:foreign_key].to_s :
                             "#{inverse}#{relation.foreign_key_suffix}"
        end

        # Is this association type embedded?
        #
        # @return [ false ] Always false.
        #
        # @since 7.0
        def embedded?; false; end

        # The default for validation the association object.
        #
        # @return [ true ] Always true.
        #
        # @since 7.0
        def validation_default; true; end

        # Does this association type store the foreign key?
        #
        # @return [ true ] Always true.
        #
        # @since 7.0
        def stores_foreign_key?; false; end

        # Get a builder object for creating a relationship of this type between two objects.
        #
        # @params [ Object ] The base.
        # @params [ Object ] The object to relate.
        #
        # @return [ Association::HasMany::Builder ] The builder object.
        #
        # @since 7.0
        def builder(base, object)
          Builder.new(base, self, object || [])
        end

        # Get the relation proxy class for this association type.
        #
        # @return [ Association::HasMany::Proxy ] The proxy class.
        #
        # @since 7.0
        def relation
          Proxy
        end

        # The criteria used for querying this relation.
        #
        # @return [ Mongoid::Criteria ] The criteria used for querying this relation.
        #
        # @since 7.0
        def criteria(object, type)
          relation.criteria(self, object, type)
        end

        # The type of this association if it's polymorphic.
        #
        # @note Only relevant for polymorphic relations.
        #
        # @return [ String, nil ] The type field.
        #
        # @since 7.0
        def type
          @type ||= "#{as}_type" if polymorphic?
        end

        # Add polymorphic query criteria to a Criteria object, if this association is
        #  polymorphic.
        #
        # @params [ Mongoid::Criteria ] criteria The criteria object to add to.
        # @params [ Class ] object_class The object class.
        #
        # @return [ Mongoid::Criteria ] The criteria object.
        #
        # @since 7.0
        def add_polymorphic_criterion(criteria, object_class)
          if polymorphic?
            criteria.where(type => object_class.name)
          else
            criteria
          end
        end

        # Is this association polymorphic?
        #
        # @return [ true, false ] Whether this association is polymorphic.
        #
        # @since 7.0
        def polymorphic?
          @polymorphic ||= !!as
        end

        # Whether trying to bind an object using this association should raise
        # an error.
        #
        # @params [ Document ] The document to be bound.
        #
        # @return [ true, false ] Whether the document can be bound.
        def bindable?(doc)
          forced_nil_inverse? || (!!inverse && doc.fields.keys.include?(foreign_key))
        end

        # The nested builder object.
        #
        # @params [ Hash ] The attributes to use to build the association object.
        # @params [ Hash ] The options for the association.
        #
        # @return [ Association::Nested::Many ] The Nested Builder object.
        #
        # @since 7.0
        def nested_builder(attributes, options)
          Nested::Many.new(self, attributes, options)
        end

        # Get the path calculator for the supplied document.
        #
        # @example Get the path calculator.
        #   Proxy.path(document)
        #
        # @param [ Document ] document The document to calculate on.
        #
        # @return [ Root ] The root atomic path calculator.
        #
        # @since 2.1.0
        def path(document)
          Mongoid::Atomic::Paths::Root.new(document)
        end

        private

        def polymorphic_inverses(other)
          [ as ]
        end

        def determine_inverses(other)
          matches = (other || relation_class).relations.values.select do |rel|
            relation_complements.include?(rel.class) &&
                rel.relation_class_name == inverse_class_name

          end
          if matches.size > 1
            return [ default_inverse.name ] if default_inverse
            raise Errors::AmbiguousRelationship.new(relation_class, @owner_class, name, matches)
          end
          matches.collect { |m| m.name } unless matches.blank?
        end

        def default_primary_key
          PRIMARY_KEY_DEFAULT
        end
      end
    end
  end
end
