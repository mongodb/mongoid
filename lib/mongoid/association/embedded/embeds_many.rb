# frozen_string_literal: true

require 'mongoid/association/embedded/embeds_many/binding'
require 'mongoid/association/embedded/embeds_many/buildable'
require 'mongoid/association/embedded/embeds_many/proxy'

module Mongoid
  module Association
    module Embedded

      # The EmbedsMany type association.
      class EmbedsMany
        include Relatable
        include Buildable

        # The options available for this type of association, in addition to the
        # common ones.
        #
        # @return [ Array<Symbol> ] The extra valid options.
        ASSOCIATION_OPTIONS = [
            :as,
            :cascade_callbacks,
            :cyclic,
            :order,
            :store_as,
            :before_add,
            :after_add,
            :before_remove,
            :after_remove
        ]

        # The complete list of valid options for this association, including
        # the shared ones.
        #
        # @return [ Array<Symbol> ] The valid options.
        VALID_OPTIONS = (ASSOCIATION_OPTIONS + SHARED_OPTIONS).freeze

        # Setup the instance methods, fields, etc. on the association owning class.
        #
        # @return [ self ]
        def setup!
          setup_instance_methods!
          @owner_class.embedded_relations = @owner_class.embedded_relations.merge(name => self)
          @owner_class.aliased_fields[name.to_s] = store_as if store_as
          self
        end

        # The field key used to store the list of association objects.
        #
        # @return [ String ] The field name.
        def store_as
          @store_as ||= (@options[:store_as].try(:to_s) || name.to_s)
        end

        # The key that is used to get the attributes for the associated object.
        #
        # @return [ String ] The name of the field used to store the association.
        def key
          store_as.to_s
        end

        # Is this association type embedded?
        #
        # @return [ true ] Always true.
        def embedded?; true; end

        # Get the default validation setting for the association. Determines if
        # by default a validates associated will occur.
        #
        # @example Get the validation default.
        #   Proxy.validation_default
        #
        # @return [ true ] Always true.
        def validation_default; true; end

        # Does this association type store the foreign key?
        #
        # @return [ false ] Always false.
        def stores_foreign_key?; false; end

        # The primary key
        #
        # @return [ nil ] Not relevant for this association
        def primary_key; end

        # Get the association proxy class for this association type.
        #
        # @return [ Association::Embedded::EmbedsMany::Proxy ] The proxy class.
        def relation
          Proxy
        end

        # Is this association polymorphic?
        #
        # @return [ true | false ] Whether this association is polymorphic.
        def polymorphic?
          @polymorphic ||= !!@options[:as]
        end

        # The field used to store the type of the related object.
        #
        # @note Only relevant if the association is polymorphic.
        #
        # @return [ String | nil ] The field for storing the associated object's type.
        def type
          @type ||= "#{as}_type" if polymorphic?
        end

        # The nested builder object.
        #
        # @param [ Hash ] attributes The attributes to use to build the association object.
        # @param [ Hash ] options The options for the association.
        #
        # @return [ Association::Nested::Many ] The Nested Builder object.
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
        # @return [ Mongoid::Atomic::Paths::Embedded::Many ]
        #   The embedded many atomic path calculator.
        def path(document)
          Mongoid::Atomic::Paths::Embedded::Many.new(document)
        end

        # Get a criteria object for searching given a parent and children documents.
        #
        # @param [ Document ] base The base document.
        # @param [ Document ] target The children documents.
        def criteria(base, target)
          criterion = klass.scoped
          criterion.embedded = true
          criterion.documents = target
          criterion.parent_document = base
          criterion.association = self
          apply_ordering(criterion)
        end

        private

        def apply_ordering(criteria)
          order ? criteria.order_by(order) : criteria
        end

        def setup_instance_methods!
          define_getter!
          define_setter!
          define_existence_check!
          define_builder!
          define_creator!
          @owner_class.cyclic = true if cyclic?
          @owner_class.validates_associated(name) if validate?
        end

        def relation_complements
          @relation_complements ||= [ Embedded::EmbeddedIn ].freeze
        end

        def polymorphic_inverses(other = nil)
          [ as ]
        end

        def determine_inverses(other)
          matches = relation_class.relations.values.select do |rel|
            relation_complements.include?(rel.class) &&
              # https://jira.mongodb.org/browse/MONGOID-4882
              rel.relation_class_name.sub(/\A::/, '') == inverse_class_name
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
