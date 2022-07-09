# frozen_string_literal: true

module Mongoid
  class Criteria
    module Queryable

      # This is a smart hash for use with options and selectors.
      class Smash < Hash

        # @attribute [r] aliases The aliases.
        attr_reader :aliases

        # @attribute [r] serializers The serializers.
        attr_reader :serializers

        # @attribute [r] associations The associations.
        attr_reader :associations

        # @attribute [r] aliased_associations The aliased_associations.
        attr_reader :aliased_associations

        # Perform a deep copy of the smash.
        #
        # @example Perform a deep copy.
        #   smash.__deep_copy__
        #
        # @return [ Smash ] The copied hash.
        def __deep_copy__
          self.class.new(aliases, serializers, associations, aliased_associations) do |copy|
            each_pair do |key, value|
              copy.store(key, value.__deep_copy__)
            end
          end
        end

        # Initialize the new selector.
        #
        # @example Initialize the new selector.
        #   Queryable::Smash.new(aliases, serializers)
        #
        # @param [ Hash ] aliases A hash of mappings from aliases to the actual
        #   field names in the database.
        # @param [ Hash ] serializers An optional hash of objects that are
        #   responsible for serializing values. The keys of the hash must be
        #   strings that match the field name, and the values must respond to
        #   #localized? and #evolve(object).
        # @param [ Hash ] associations An optional hash of names to association
        #   objects.
        # @param [ Hash ] aliased_associations An optional hash of mappings from
        #   aliases for associations to their actual field names in the database.
        def initialize(aliases = {}, serializers = {}, associations = {}, aliased_associations = {})
          @aliases = aliases
          @serializers = serializers
          @associations = associations
          @aliased_associations = aliased_associations
          yield(self) if block_given?
        end

        # Get an item from the smart hash by the provided key.
        #
        # @example Get an item by the key.
        #   smash["test"]
        #
        # @param [ String ] key The key.
        #
        # @return [ Object ] The found object.
        def [](key)
          fetch(aliases[key]) { super }
        end

        private

        # Get the localized value for the key if needed. If the field uses
        # localization the current locale will be appended to the key in
        # MongoDB dot notation.
        #
        # @api private
        #
        # @example Get the normalized key name.
        #   smash.localized_key("field", serializer)
        #
        # @param [ String ] name The name of the field.
        # @param [ Object ] serializer The optional field serializer.
        #
        # @return [ String ] The normalized key.
        def localized_key(name, serializer)
          serializer && serializer.localized? ? "#{name}.#{::I18n.locale}" : name
        end

        # Get the pair of objects needed to store the value in a hash by the
        # provided key. This is the database field name and the serializer.
        #
        # @api private
        #
        # @example Get the name and serializer.
        #   smash.storage_pair("id")
        #
        # @param [ Symbol | String ] key The key provided to the selection.
        #
        # @return [ Array<String, Object> ] The name of the db field and
        #   serializer.
        def storage_pair(key)
          field = key.to_s
          name = Fields.database_field_name(field, associations, aliases, aliased_associations)
          [ name, get_serializer(name) ]
        end

        private

        # Retrieves the serializer for the given name. If the name exists in
        # the serializers hash then return that immediately, otherwise
        # recursively look through the associations and find the appropriate
        # field.
        #
        # @param [ String ] name The name of the db field.
        #
        # @return [ Object ] The serializer.
        def get_serializer(name)
          if s = serializers[name]
            s
          else
            Fields.traverse_association_tree(name, serializers, associations, aliased_associations)
          end
        end
      end
    end
  end
end
