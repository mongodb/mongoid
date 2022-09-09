# frozen_string_literal: true

module Mongoid
  module Persistable

    # Defines behavior for persistence operations that delete documents.
    module Deletable
      extend ActiveSupport::Concern

      # Remove the document from the database.
      #
      # @example Remove the document.
      #   document.remove
      #
      # @param [ Hash ] options Options to pass to remove.
      #
      # @return [ TrueClass ] True.
      def delete(options = {})
        prepare_delete do
          unless options[:persist] == false
            if embedded?
              delete_as_embedded(options)
            else
              delete_as_root
            end
          end
        end
      end
      alias :remove :delete

      private

      # Get the atomic deletes for the operation.
      #
      # @api private
      #
      # @example Get the atomic deletes.
      #   document.atomic_deletes
      #
      # @return [ Hash ] The atomic deletes.
      def atomic_deletes
        { atomic_delete_modifier => { atomic_path => _index ? { "_id" => _id } : true }}
      end

      # Delete the embedded document.
      #
      # @api private
      #
      # @example Delete the embedded document.
      #   document.delete_as_embedded
      #
      # @param [ Hash ] options The deletion options.
      #
      # @return [ true ] If the operation succeeded.
      def delete_as_embedded(options = {})
        _parent.remove_child(self) if notifying_parent?(options)
        if _parent.persisted?
          selector = _parent.atomic_selector
          _root.collection.find(selector).update_one(
              positionally(selector, atomic_deletes),
              session: _session)
        end
        true
      end

      # Delete the root document.
      #
      # @api private
      #
      # @example Delete the root document.
      #   document.delete_as_root
      #
      # @return [ true ] If the document was removed.
      def delete_as_root
        collection.find(atomic_selector).delete_one(session: _session)
        true
      end

      # Are we needing to notify the parent document of the deletion.
      #
      # @api private
      #
      # @example Are we notifying the parent.
      #   document.notifying_parent?(suppress: true)
      #
      # @param [ Hash ] options The delete options.
      #
      # @return [ true | false ] If the parent should be notified.
      def notifying_parent?(options = {})
        !options.delete(:suppress)
      end

      # Prepare the delete operation.
      #
      # @api private
      #
      # @example Prepare the delete operation.
      #   document.prepare_delete do
      #     collection.find(atomic_selector).remove
      #   end
      #
      # @return [ Object ] The result of the block.
      def prepare_delete
        raise Errors::ReadonlyDocument.new(self.class) if readonly?
        yield(self)
        freeze
        self.destroyed = true
      end

      module ClassMethods

        # Delete all documents given the supplied conditions. If no conditions
        # are passed, the entire collection will be dropped for performance
        # benefits. Does not fire any callbacks.
        #
        # @example Delete matching documents from the collection.
        #   Person.delete_all({ :title => "Sir" })
        #
        # @example Delete all documents from the collection.
        #   Person.delete_all
        #
        # @param [ Hash ] conditions Optional conditions to delete by.
        #
        # @return [ Integer ] The number of documents deleted.
        def delete_all(conditions = {})
          selector = hereditary? ? conditions.merge(discriminator_key.to_sym => discriminator_value) : conditions
          where(selector).delete
        end
      end
    end
  end
end
