require 'mongoid/association/referenced/has_and_belongs_to_many/binding'
require 'mongoid/association/referenced/has_and_belongs_to_many/buildable'
require 'mongoid/association/referenced/has_and_belongs_to_many/proxy'
require 'mongoid/association/referenced/has_and_belongs_to_many/eager'

module Mongoid
  module Association
    module Referenced

      class HasAndBelongsToMany
        include Relatable
        include Buildable

        # The options available for this type of association, in addition to the
        # common ones.
        #
        # @return [ Array<Symbol> ] The extra valid options.
        #
        # @since 7.0
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
            :primary_key
        ].freeze

        # The complete list of valid options for this association, including
        # the shared ones.
        #
        # @return [ Array<Symbol> ] The valid options.
        #
        # @since 7.0
        VALID_OPTIONS = (ASSOCIATION_OPTIONS + SHARED_OPTIONS).freeze

        # The type of the field holding the foreign key.
        #
        # @return [ Array ]
        #
        # @since 7.0
        FOREIGN_KEY_FIELD_TYPE = Array

        # The list of association complements.
        #
        # @return [ Array<Association> ] The association complements.
        #
        # @since 7.0
        def relation_complements
          @relation_complements ||= [ self.class ].freeze
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

        # Is this association type embedded?
        #
        # @return [ false ] Always false.
        #
        # @since 7.0
        def embedded?; false; end

        # The default for validation the association object.
        #
        # @return [ false ] Always false.
        #
        # @since 7.0
        def validation_default; true; end

        def forced_nil_inverse?
          @forced_nil_inverse ||= @options.key?(:inverse_of) && !@options[:inverse_of]
        end

        # Does this association type store the foreign key?
        #
        # @return [ true ] Always true.
        #
        # @since 7.0
        def stores_foreign_key?; true; end

        # Get the relation proxy class for this association type.
        #
        # @return [ Association::HasAndBelongsToMany::Proxy ] The proxy class.
        #
        # @since 7.0
        def relation
          Proxy
        end

        # Get the foreign key field for saving the association reference.
        #
        # @return [ String ] The foreign key field for saving the association reference.
        #
        # @since 7.0
        def foreign_key
          @foreign_key ||= @options[:foreign_key] ? @options[:foreign_key].to_s : relation.foreign_key(name)
        end

        # The criteria used for querying this relation.
        #
        # @return [ Mongoid::Criteria ] The criteria used for querying this relation.
        #
        # @since 7.0
        def criteria(object, type)
          relation.criteria(self, object, type)
        end

        # Get the foreign key field on the inverse.
        #
        # @return [ String ] The foreign key field for saving the association reference
        #  on the inverse side.
        #
        # @since 7.0
        def inverse_foreign_key
          if @options.key?(:inverse_of)
            inverse_of ? "#{inverse_of.to_s.singularize}#{relation.foreign_key_suffix}" : nil
          else
            "#{inverse_class_name.demodulize.underscore}#{relation.foreign_key_suffix}"
          end
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

        # Get the foreign key setter on the inverse.
        #
        # @return [ String ] The foreign key setter for saving the association reference
        #  on the inverse side.
        #
        # @since 7.0
        def inverse_foreign_key_setter
          @inverse_foreign_key_setter ||= "#{inverse_foreign_key}=" if inverse_foreign_key
        end

        # The nested builder object.
        #
        # @params [ Hash ] The attributes to use to build the association object.
        # @params [ Hash ] The options for the association.
        #
        # @return [ Association::Nested::One ] The Nested Builder object.
        #
        # @since 7.0
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
        #
        # @since 2.1.0
        def path(document)
          Mongoid::Atomic::Paths::Root.new(document)
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
              :save,
              :after,
              if: ->(doc){ doc._syncable?(assoc) }
          ) do |doc|
            doc.update_inverse_keys(assoc)
          end
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
