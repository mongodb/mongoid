# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Association
    module Referenced

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
        #           autosaved associations.
        #   document.changed_for_autosave?
        #
        # @since 3.1.3
        def changed_for_autosave?(doc)
          doc.new_record? || doc.changed? || doc.marked_for_destruction?
        end

        # Define the autosave method on an association's owning class for
        # an associated object.
        #
        # @example Define the autosave method:
        #   Association::Referenced::Autosave.define_autosave!(association)
        #
        # @param [ Association ] association The association for which autosaving is enabled.
        #
        # @return [ Class ] The association's owner class.
        #
        # @since 7.0
        def self.define_autosave!(association)
          association.inverse_class.tap do |klass|
            save_method = :"autosave_documents_for_#{association.name}"
            klass.send(:define_method, save_method) do
              if before_callback_halted?
                self.before_callback_halted = false
              else
                __autosaving__ do
                  if relation = ivar(association.name)
                    Array(relation).each do |doc|
                      doc.with(persistence_context) do |d|
                        d.save
                      end
                    end
                  end
                end
              end
            end
            klass.after_save save_method, unless: :autosaved?
          end
        end
      end
    end
  end
end
