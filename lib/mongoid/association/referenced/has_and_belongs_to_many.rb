# frozen_string_literal: true

require 'mongoid/association/referenced/has_and_belongs_to_many/binding'
require 'mongoid/association/referenced/has_and_belongs_to_many/buildable'
require 'mongoid/association/referenced/has_and_belongs_to_many/proxy'
require 'mongoid/association/referenced/has_and_belongs_to_many/eager'

module Mongoid
  module Association
    module Referenced

      # The HasAndBelongsToMany type association.
      class HasAndBelongsToMany
        include Relatable
        include Buildable

        # The options available for this type of association, in addition to the
        # common ones.
        #
        # @return [ Array<Symbol> ] The extra valid options.
        ASSOCIATION_OPTIONS = [
            :after_add,
            :after_remove,
            :autosave,
            :before_add,
            :before_remove,
            :counter_cache,
            :dependent,
            :foreign_key,
            :index,
            :order,
            :primary_key,
            :inverse_primary_key,
            :inverse_foreign_key,
            :scope,
        ].freeze

        # The complete list of valid options for this association, including
        # the shared ones.
        #
        # @return [ Array<Symbol> ] The valid options.
        VALID_OPTIONS = (ASSOCIATION_OPTIONS + SHARED_OPTIONS).freeze

        # The type of the field holding the foreign key.
        #
        # @return [ Array ]
        FOREIGN_KEY_FIELD_TYPE = Array

        # The default foreign key suffix.
        #
        # @return [ String ] '_ids'
        FOREIGN_KEY_SUFFIX = '_ids'.freeze

        # The list of association complements.
        #
        # @return [ Array<Association> ] The association complements.
        def relation_complements
          @relation_complements ||= [ self.class ].freeze
        end

        # Setup the instance methods, fields, etc. on the association owning class.
        #
        # @return [ self ]
        def setup!
          setup_instance_methods!
          self
        end

        # Is this association type embedded?
        #
        # @return [ false ] Always false.
        def embedded?; false; end

        # The default for validation the association object.
        #
        # @return [ false ] Always false.
        def validation_default; true; end

        # Are ids only saved on this side of the association?
        #
        # @return [ true | false ] Whether this association has a forced nil inverse.
        def forced_nil_inverse?
          @forced_nil_inverse ||= @options.key?(:inverse_of) && !@options[:inverse_of]
        end

        # Does this association type store the foreign key?
        #
        # @return [ true ] Always true.
        def stores_foreign_key?; true; end

        # Get the association proxy class for this association type.
        #
        # @return [ Association::HasAndBelongsToMany::Proxy ] The proxy class.
        def relation
          Proxy
        end

        # Get the foreign key field for saving the association reference.
        #
        # @return [ String ] The foreign key field for saving the association reference.
        def foreign_key
          @foreign_key ||= @options[:foreign_key] ? @options[:foreign_key].to_s :
                             default_foreign_key_field
        end

        # The criteria used for querying this association.
        #
        # @return [ Mongoid::Criteria ] The criteria used for querying this association.
        def criteria(base, id_list = nil)
          query_criteria(id_list || base.send(foreign_key))
        end

        # Get the foreign key field on the inverse.
        #
        # @return [ String ] The foreign key field for saving the association reference
        #  on the inverse side.
        def inverse_foreign_key
          if @options.key?(:inverse_foreign_key)
            @options[:inverse_foreign_key]
          elsif @options.key?(:inverse_of)
            inverse_of ? "#{inverse_of.to_s.singularize}#{FOREIGN_KEY_SUFFIX}" : nil
          elsif inv = inverse_association&.foreign_key
            inv
          else
            "#{inverse_class_name.demodulize.underscore}#{FOREIGN_KEY_SUFFIX}"
          end
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

        # Get the foreign key setter on the inverse.
        #
        # @return [ String ] The foreign key setter for saving the association reference
        #  on the inverse side.
        def inverse_foreign_key_setter
          @inverse_foreign_key_setter ||= "#{inverse_foreign_key}=" if inverse_foreign_key
        end

        # The nested builder object.
        #
        # @param [ Hash ] attributes The attributes to use to build the association object.
        # @param [ Hash ] options The options for the association.
        #
        # @return [ Association::Nested::One ] The Nested Builder object.
        def nested_builder(attributes, options)
          Nested::Many.new(self, attributes, options)
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
          define_dependency!
          define_existence_check!
          define_autosaver!
          define_counter_cache_callbacks!
          create_foreign_key_field!
          setup_index!
          setup_syncing!
          @owner_class.validates_associated(name) if validate?
          self
        end

        def index_spec
          { key => 1 }
        end

        def default_primary_key
          PRIMARY_KEY_DEFAULT
        end

        def default_foreign_key_field
          @default_foreign_key_field ||= "#{name.to_s.singularize}#{FOREIGN_KEY_SUFFIX}"
        end

        def setup_syncing!
          unless forced_nil_inverse?
            synced_save
            synced_destroy
          end
        end

        def synced_destroy
          assoc = self
          inverse_class.set_callback(
              :destroy,
              :after
          ) do |doc|
            doc.remove_inverse_keys(assoc)
          end
        end

        def synced_save
          assoc = self
          inverse_class.set_callback(
              :persist_parent,
              :after,
              if: ->(doc){ doc._syncable?(assoc) }
          ) do |doc|
            doc.update_inverse_keys(assoc)
          end
        end

        def create_foreign_key_field!
          inverse_class.aliased_associations[foreign_key] = name.to_s
          @owner_class.field(
              foreign_key,
              type: FOREIGN_KEY_FIELD_TYPE,
              identity: true,
              overwrite: true,
              association: self,
              default: nil
          )
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

        def with_ordering(criteria)
          if order
            criteria.order_by(order)
          else
            criteria
          end
        end

        def query_criteria(id_list)
          crit = relation_class.criteria
          crit = crit.apply_scope(scope)
          crit = crit.all_of(primary_key => {"$in" => id_list || []})
          with_ordering(crit)
        end
      end
    end
  end
end
