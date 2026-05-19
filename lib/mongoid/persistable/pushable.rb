# frozen_string_literal: true

module Mongoid
  module Persistable
    # Defines behavior for $push and $addToSet operations.
    module Pushable
      extend ActiveSupport::Concern

      # Add the single values to the arrays only if the value does not already
      # exist in the array.
      #
      # @example Add the values to the sets.
      #   document.add_to_set(names: "James", aliases: "Bond")
      #
      # @param [ Hash ] adds The field/value pairs to add.
      #
      # @return [ Document ] The document.
      def add_to_set(adds)
        raise Errors::ReadonlyDocument.new(self.class) if readonly? && !Mongoid.legacy_readonly

        ops = {}
        adds.each do |field, value|
          access = database_field_name(field)
          existing = send(access) || attributes[access]
          if existing.nil?
            attributes[access] = []
            # Read the value out of attributes:
            # https://jira.mongodb.org/browse/MONGOID-4874
            existing = attributes[access]
          end
          values = [ value ].flatten(1)
          values.each do |val|
            existing.push(val) unless existing.include?(val)
          end
          remove_change(access)
          ops[atomic_attribute_name(access)] = { '$each' => values }
        end

        return self unless persisted?

        _stage_atomic_update('$addToSet', ops)
      end

      # Push a single value or multiple values onto arrays.
      #
      # @example Push a single value onto arrays.
      #   document.push(names: "James", aliases: "007")
      #
      # @example Push multiple values onto arrays.
      #   document.push(names: [ "James", "Bond" ])
      #
      # @param [ Hash ] pushes The $push operations.
      #
      # @return [ Document ] The document.
      def push(pushes)
        raise Errors::ReadonlyDocument.new(self.class) if readonly? && !Mongoid.legacy_readonly

        ops = {}
        pushes.each do |field, value|
          access = database_field_name(field)
          existing = send(access) || begin
            attributes[access] ||= []
            attributes[access]
          end
          values = [ value ].flatten(1)
          values.each { |val| existing.push(val) }
          remove_change(access)
          ops[atomic_attribute_name(access)] = { '$each' => values }
        end

        return self unless persisted?

        _stage_atomic_update('$push', ops)
      end
    end
  end
end
