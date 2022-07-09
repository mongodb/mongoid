# frozen_string_literal: true

require 'mongoid/association/referenced/has_one/binding'
require 'mongoid/association/referenced/has_one/buildable'
require 'mongoid/association/referenced/has_one/proxy'
require 'mongoid/association/referenced/has_one/eager'

module Mongoid
  module Association
    module Referenced

      # The has_one association.
      class HasOne
        include Relatable
        include Buildable

        # The options available for this type of association, in addition to the
        # common ones.
        #
        # @return [ Array<Symbol> ] The extra valid options.
        ASSOCIATION_OPTIONS = [
            :as,
            :autobuild,
            :autosave,
            :dependent,
            :foreign_key,
            :primary_key,
            :scope,
        ].freeze

        # The complete list of valid options for this association, including
        # the shared ones.
        #
        # @return [ Array<Symbol> ] The valid options.
        VALID_OPTIONS = (ASSOCIATION_OPTIONS + SHARED_OPTIONS).freeze

        # The default foreign key suffix.
        #
        # @return [ String ] '_id'
        FOREIGN_KEY_SUFFIX = '_id'.freeze

        # The list of association complements.
        #
        # @return [ Array<Association> ] The association complements.
        def relation_complements
          @relation_complements ||= [ Referenced::BelongsTo ].freeze
        end

        # Setup the instance methods, fields, etc. on the association owning class.
        #
        # @return [ self ]
        def setup!
          setup_instance_methods!
          self
        end

        # Get the foreign key field for saving the association reference.
        #
        # @return [ String ] The foreign key field for saving the
        #   association reference.
        def foreign_key
          @foreign_key ||= @options[:foreign_key] ? @options[:foreign_key].to_s :
                             default_foreign_key_field
        end

        # Is this association type embedded?
        #
        # @return [ false ] Always false.
        def embedded?; false; end

        # The default for validation the association object.
        #
        # @return [ true ] Always true.
        def validation_default; true; end

        # Get the association proxy class for this association type.
        #
        # @return [ Association::HasOne::Proxy ] The proxy class.
        def relation
          Proxy
        end

        # The nested builder object.
        #
        # @param [ Hash ] attributes The attributes to use to build the association object.
        # @param [ Hash ] options The options for the association.
        #
        # @return [ Association::Nested::Many ] The Nested Builder object.
        def nested_builder(attributes, options)
          Nested::One.new(self, attributes, options)
        end

        # Is this association polymorphic?
        #
        # @return [ true | false ] Whether this association is polymorphic.
        def polymorphic?
          @polymorphic ||= !!as
        end

        # The type of this association if it's polymorphic.
        #
        # @note Only relevant for polymorphic associations.
        #
        # @return [ String | nil ] The type field.
        def type
          @type ||= "#{as}_type" if polymorphic?
        end

        # Whether trying to bind an object using this association should raise
        # an error.
        #
        # @param [ Document ] doc The document to be bound.
        #
        # @return [ true | false ] Whether the document can be bound.
        def bindable?(doc)
          forced_nil_inverse? || (!!inverse && doc.fields.keys.include?(foreign_key))
        end

        def stores_foreign_key?; false; end

        # Get the path calculator for the supplied document.
        #
        # @example Get the path calculator.
        #   Proxy.path(document)
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

        # Setup the instance methods on the class having this association type.
        #
        # @return [ self ]
        def setup_instance_methods!
          define_getter!
          define_setter!
          define_existence_check!
          define_builder!
          define_creator!
          define_autosaver!
          polymorph!
          define_dependency!
          @owner_class.validates_associated(name) if validate?
          self
        end

        def default_foreign_key_field
          @default_foreign_key_field ||= "#{inverse}#{FOREIGN_KEY_SUFFIX}"
        end

        def polymorphic_inverses(other)
          [ as ]
        end

        def determine_inverses(other)
          matches = (other || relation_class).relations.values.select do |rel|
            relation_complements.include?(rel.class) &&
                rel.relation_class_name == inverse_class_name

          end
          if matches.size > 1
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
