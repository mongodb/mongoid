# encoding: utf-8
module Mongoid
  module Relations

    # This module contains the behaviour for auto-saving relations in
    # different collections.
    module AutoSave
      extend ActiveSupport::Concern

      included do
        class_attribute :autosaved_relations
        self.autosaved_relations = []
      end

      # Used to prevent infinite loops in associated autosaves.
      #
      # @example Is the document autosaved?
      #   document.autosaved?
      #
      # @return [ true, false ] Has the document already been autosaved?
      #
      # @since 3.0.0
      def autosaved?
        Threaded.autosaved?(self)
      end

      # Begin the associated autosave.
      #
      # @example Begin autosave.
      #   document.begin_autosave
      #
      # @since 3.0.0
      def begin_autosave
        Threaded.begin_autosave(self)
      end

      # Exit the associated autosave.
      #
      # @example Exit autosave.
      #   document.exit_autosave
      #
      # @since 3.0.0
      def exit_autosave
        Threaded.exit_autosave(self)
      end

      module ClassMethods

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
          if metadata.autosave? && autosavable?(metadata)
            autosaved_relations.push(metadata.name)
            set_callback :save, :after, unless: :autosaved? do |document|
              # @todo: Durran: Remove with Rails 4 after callback termination.
              if before_callback_halted?
                self.before_callback_halted = false
              else
                begin_autosave
                relation = document.send(metadata.name)
                if relation
                  (relation.do_or_do_not(:in_memory) || Array.wrap(relation)).each do |doc|
                    doc.save
                  end
                end
                exit_autosave
              end
            end
          end
        end

        # Can the autosave be added?
        #
        # @example Can the autosave be added?
        #   Person.autosavable?(metadata)
        #
        # @param [ Metadata ] metadata The relation metadata.
        #
        # @return [ true, false ] If the autosave is able to be added.
        #
        # @since 3.0.0
        def autosavable?(metadata)
          !autosaved_relations.include?(metadata.name) && !metadata.embedded?
        end
      end
    end
  end
end
