# frozen_string_literal: true

module Mongoid
  module Persistable
    # Defines behavior for $pull and $pullAll operations.
    module Pullable
      extend ActiveSupport::Concern

      # Pull single values from the provided arrays.
      #
      # @example Pull a value from the array.
      #   document.pull(names: "Jeff", levels: 5)
      #
      # @note If duplicate values are found they will all be pulled.
      #
      # @param [ Hash ] pulls The field/value pull pairs.
      #
      # @return [ Document ] The document.
      def pull(pulls)
        raise Errors::ReadonlyDocument.new(self.class) if readonly? && !Mongoid.legacy_readonly
        return self unless persisted?

        ops = {}
        pulls.each do |field, value|
          access = database_field_name(field)
          (send(access) || []).delete(value)
          remove_change(access)
          ops[atomic_attribute_name(access)] = value
        end

        return self if ops.empty?

        selector = atomic_selector
        Mongoid.changeset do
          Mongoid.current_changeset.add(
            Changeset::Entry.new(
              type: :update,
              collection: collection(_root),
              selector: selector,
              payload: positionally(selector, { '$pull' => ops }),
              document: self,
              session: _session
            )
          )
        end
        self
      end

      # Pull multiple values from the provided array fields.
      #
      # @example Pull values from the arrays.
      #   document.pull_all(names: [ "Jeff", "Bob" ], levels: [ 5, 6 ])
      #
      # @param [ Hash ] pulls The pull all operations.
      #
      # @return [ Document ] The document.
      def pull_all(pulls)
        raise Errors::ReadonlyDocument.new(self.class) if readonly? && !Mongoid.legacy_readonly
        return self unless persisted?

        ops = {}
        pulls.each do |field, value|
          access = database_field_name(field)
          existing = send(access) || []
          value.each { |val| existing.delete(val) }
          remove_change(access)
          ops[atomic_attribute_name(access)] = value
        end

        return self if ops.empty?

        selector = atomic_selector
        Mongoid.changeset do
          Mongoid.current_changeset.add(
            Changeset::Entry.new(
              type: :update,
              collection: collection(_root),
              selector: selector,
              payload: positionally(selector, { '$pullAll' => ops }),
              document: self,
              session: _session
            )
          )
        end
        self
      end
    end
  end
end
