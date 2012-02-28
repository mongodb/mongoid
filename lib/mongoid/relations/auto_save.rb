# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

    # This module contains the behaviour for auto-saving relations in
    # different collections.
    module AutoSave
      extend ActiveSupport::Concern

      included do
        class_attribute :autosaved_relations
        self.autosaved_relations = []
      end

      module ClassMethods #:nodoc:

        # Set up the autosave behaviour for references many and references one
        # relations. When the option is set to true, these relations will get
        # saved automatically when the parent is first saved, but not if the
        # parent already exists in the database.
        #
        # @example Set up autosave options.
        #   Person.autosave(metadata)
        #
        # @param [ Metadata ] metadata The relation metadata.
        #
        # @since 2.0.0.rc.1
        def autosave(metadata)
          if metadata.autosave? && !autosave_added?(metadata)
            autosaved_relations.push(metadata.name)
            set_callback :save, :after do |document|
              relation = document.send(metadata.name)
              if relation
                (relation.do_or_do_not(:in_memory) || Array.wrap(relation)).each do |doc|
                  doc.save
                end
              end
            end
          end
        end

        # Has the autosave callback been added for the relation already?
        #
        # @example Has the autosave callback been added.
        #   Person.autosave_added?(metadata)
        #
        # @param [ Metadata ] metadata The relation metadata.
        #
        # @return [ true, false ] If the autosave is already added.
        #
        # @since 3.0.0
        def autosave_added?(metadata)
          autosaved_relations.include?(metadata.name)
        end
      end
    end
  end
end
