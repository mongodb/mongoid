# encoding: utf-8
module Mongoid
  module Relations

    # This module contains the behaviour for auto-saving relations in
    # different collections.
    module AutoSave
      extend ActiveSupport::Concern

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
      #   document.__autosaving__
      #
      # @since 3.1.3
      def __autosaving__
        Threaded.begin_autosave(self)
        yield
      ensure
        Threaded.exit_autosave(self)
      end

      # Check if there is changes for auto-saving
      #
      # @example Return true if there is changes on self or in
      #           autosaved relations.
      #   document.changed_for_autosave?
      #
      # @since 3.1.3
      def changed_for_autosave?(doc)
        doc.new_record? || doc.changed? || doc.marked_for_destruction?
      end

      module ClassMethods

        # Set up the autosave behaviour for references many and references one
        # relations. When the option is set to true, these relations will get
        # saved automatically when the parent saved, if they are dirty.
        #
        # @example Set up autosave options.
        #   Person.autosave(metadata)
        #
        # @param [ Metadata ] metadata The relation metadata.
        #
        # @since 2.0.0.rc.1
        def autosave(metadata)
          if metadata.autosave? && !metadata.embedded?
            save_method = :"autosave_documents_for_#{metadata.name}"
            define_method(save_method) do

              if before_callback_halted?
                self.before_callback_halted = false
              else
                __autosaving__ do
                  if relation = ivar(metadata.name)
                    options = persistence_options || {}
                    if :belongs_to == metadata.macro
                      relation.with(options).save if changed_for_autosave?(relation)
                    else
                      Array(relation).each { |d| d.with(options).save if changed_for_autosave?(d) }
                    end
                  end
                end
              end
            end

            after_save save_method, unless: :autosaved?
          end
        end

      end
    end
  end
end
