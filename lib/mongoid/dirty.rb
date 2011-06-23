# encoding: utf-8
module Mongoid #:nodoc:
  module Dirty #:nodoc:
    extend ActiveSupport::Concern
    include ActiveModel::Dirty

    # Call this method after save, so the changes can be properly switched.
    #
    # @example Move the changes to previous.
    #   person.move_changes
    def move_changes
      @validated = false
      @previously_changed = changes
      changed_attributes.clear
    end

    # Remove a change from the dirty attributes hash. Used by the single field
    # atomic updators.
    #
    # @example Remove a flagged change.
    #   model.remove_change(:field)
    #
    # @param [ Symbol, String ] name The name of the field.
    #
    # @since 2.1.0
    def remove_change(name)
      changed_attributes.delete(name.to_s)
    end

    # Gets all the new values for each of the changed fields, to be passed to
    # a MongoDB $set modifier.
    #
    # @example Get the setters for the atomic updates.
    #   person = Person.new(:title => "Sir")
    #   person.title = "Madam"
    #   person.setters # returns { "title" => "Madam" }
    #
    # @return [ Hash ] A +Hash+ of atomic setters.
    def setters
      {}.tap do |modifications|
        changes.each do |field, changes|
          key = embedded? ? "#{_position}.#{field}" : field
          modifications[key] = changes[1]
        end
      end
    end
  end
end
