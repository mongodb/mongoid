require 'mongoid/association/embedded/embedded_in/binding'
require 'mongoid/association/embedded/embedded_in/buildable'
require 'mongoid/association/embedded/embedded_in/proxy'

module Mongoid
  module Association
    module Embedded

      # The EmbeddedIn type association.
      #
      # @since 7.0
      class EmbeddedIn
        include Relatable
        include Buildable

        # The options available for this type of association, in addition to the
        # common ones.
        #
        # @return [ Array<Symbol> ] The extra valid options.
        #
        # @since 7.0
        ASSOCIATION_OPTIONS = [
            :autobuild,
            :cyclic,
            :polymorphic,
            :touch
        ].freeze

        # The complete list of valid options for this association, including
        # the shared ones.
        #
        # @return [ Array<Symbol> ] The valid options.
        #
        # @since 7.0
        VALID_OPTIONS = (ASSOCIATION_OPTIONS + SHARED_OPTIONS).freeze

        # Setup the instance methods, fields, etc. on the association owning class.
        #
        # @return [ self ]
        #
        # @since 7.0
        def setup!
          setup_instance_methods!
          @owner_class.embedded = true
          self
        end

        # Is this association type embedded?
        #
        # @return [ true ] Always true.
        #
        # @since 7.0
        def embedded?; true; end

        # The primary key
        #
        # @return [ nil ] Not relevant for this relation
        def primary_key; end

        # Does this association type store the foreign key?
        #
        # @return [ false ] Always false.
        #
        # @since 7.0
        def stores_foreign_key?; false; end

        # The default for validating the association object.
        #
        # @return [ false ] Always false.
        #
        # @since 7.0
        def validation_default; false; end

        # The key that is used to get the attributes for the associated object.
        #
        # @return [ String ] The name of the relation.
        #
        # @since 7.0
        def key
          @key ||= name.to_s
        end

        # Get the relation proxy class for this association type.
        #
        # @return [ Association::Embedded::EmbeddedIn::Proxy ] The proxy class.
        #
        # @since 7.0
        def relation
          Proxy
        end

        # Is this association polymorphic?
        #
        # @return [ true, false ] Whether this association is polymorphic.
        #
        # @since 7.0
        def polymorphic?
          !!@options[:polymorphic]
        end

        # The nested builder object.
        #
        # @param [ Hash ] attributes The attributes to use to build the association object.
        # @param [ Hash ] options The options for the association.
        #
        # @return [ Association::Nested::One ] The Nested Builder object.
        #
        # @since 7.0
        def nested_builder(attributes, options)
          Nested::One.new(self, attributes, options)
        end

        private

        def setup_instance_methods!
          define_getter!
          define_setter!
          define_existence_check!
          define_builder!
          define_creator!
          define_counter_cache_callbacks!
          define_touchable!
        end

        def relation_complements
          @relation_complements ||= [ Embedded::EmbedsMany,
                                      Embedded::EmbedsOne ].freeze
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
          matches.collect { |m| m.name } unless matches.blank?
        end
      end
    end
  end
end
