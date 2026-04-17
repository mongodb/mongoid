# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      # Mixin module included into Mongoid::Document which adds
      # the ability to automatically save opposite-side documents
      # in referenced associations when saving the subject document.
      module AutoSave
        extend ActiveSupport::Concern

        # Used to prevent infinite loops in associated autosaves.
        #
        # @example Is the document autosaved?
        #   document.autosaved?
        #
        # @return [ true | false ] Has the document already been autosaved?
        def autosaved?
          Threaded.autosaved?(self)
        end

        # Begin the associated autosave.
        #
        # @example Begin autosave.
        #   document.__autosaving__
        def __autosaving__
          Threaded.begin_autosave(self)
          yield
        ensure
          Threaded.exit_autosave(self)
        end

        # Check if there are changes for auto-saving. Returns true if the
        # document is new, changed, or marked for destruction, or if any
        # in-memory referenced child with autosave: true recursively
        # satisfies the same condition.
        #
        # The seen set prevents infinite recursion when autosave associations
        # form a cycle (e.g. a belongs_to with autosave: true whose target
        # has a has_many with autosave: true pointing back).
        #
        # @param [ Document ] doc The document to check.
        # @param [ Set ] seen Documents already visited (cycle guard).
        #
        # @return [ true | false ] Whether the document needs autosaving.
        def changed_for_autosave?(doc, seen = Set.new)
          return false unless seen.add?(doc)

          doc.new_record? || doc.changed? || doc.marked_for_destruction? ||
            autosave_children_changed?(doc, seen)
        end

        # Define the autosave method on an association's owning class for
        # an associated object.
        #
        # @example Define the autosave method:
        #   Association::Referenced::Autosave.define_autosave!(association)
        #
        # @param [ Mongoid::Association::Relatable ] association The association for which autosaving is enabled.
        #
        # @return [ Class ] The association's owner class.
        def self.define_autosave!(association)
          association.inverse_class.tap do |klass|
            save_method = :"autosave_documents_for_#{association.name}"
            klass.send(:define_method, save_method) do
              if before_callback_halted?
                self.before_callback_halted = false
              else
                __autosaving__ do
                  if assoc_value = ivar(association.name)
                    Array(assoc_value).each do |doc|
                      next unless changed_for_autosave?(doc)

                      pc = doc.persistence_context? ? doc.persistence_context : persistence_context.for_child(doc)
                      doc.with(pc) do |d|
                        d.save
                      end
                    end
                  end
                end
              end
            end
            klass.after_persist_parent save_method, unless: :autosaved?
          end
        end

        private

        # Returns true if any in-memory referenced child with autosave: true
        # needs saving.
        #
        # @param [ Document ] doc The document whose children to check.
        # @param [ Set ] seen Cycle guard passed through from changed_for_autosave?.
        #
        # @return [ true | false ]
        def autosave_children_changed?(doc, seen)
          if Mongoid.autosave_saves_unchanged_documents?
            Mongoid::Warnings.warn_autosave_saves_unchanged_documents
            return true
          end

          doc.class.relations.values.select { |a| a.autosave? && !a.embedded? }.any? do |assoc|
            (assoc_value = doc.ivar(assoc.name)) &&
              in_memory_docs(assoc_value).any? { |child| changed_for_autosave?(child, seen) }
          end
        end

        # Returns the in-memory documents for an association value without
        # triggering a database load of any unloaded documents. Association
        # proxies expose in_memory for this purpose; a plain document (which
        # belongs_to can store directly in the ivar) is itself in-memory.
        def in_memory_docs(assoc_value)
          assoc_value.respond_to?(:in_memory) ? assoc_value.in_memory : [ assoc_value ]
        end
      end
    end
  end
end
