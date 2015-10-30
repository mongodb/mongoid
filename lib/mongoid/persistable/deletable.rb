# encoding: utf-8
module Mongoid
  module Persistable

    # Defines behaviour for persistence operations that delete documents.
    #
    # @since 4.0.0
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
      #
      # @since 1.0.0
      def delete(options = {})
        raise Errors::ReadonlyDocument.new(self.class) if readonly?
        prepare_delete do
          if embedded?
            delete_as_embedded(options)
          else
            delete_as_root
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
      #
      # @since 4.0.0
      def atomic_deletes
        { atomic_delete_modifier => { atomic_path => _index ? { "_id" => id } : true }}
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
      #
      # @since 4.0.0
      def delete_as_embedded(options = {})
        _parent.remove_child(self) if notifying_parent?(options)
        if _parent.persisted?
          selector = _parent.atomic_selector
          _root.collection.find(selector).update_one(positionally(selector, atomic_deletes))
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
      #
      # @since 4.0.0
      def delete_as_root
        collection.find(atomic_selector).delete_one
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
      # @return [ true, false ] If the parent should be notified.
      #
      # @since 4.0.0
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
      #
      # @since 4.0.0
      def prepare_delete
        cascade!
        yield(self)
        freeze
        self.destroyed = true
        true
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
        #
        # @since 1.0.0
        def delete_all(conditions = nil)
          selector = conditions || {}
          selector.merge!(_type: name) if hereditary?
          coll = collection
          deleted = coll.find(selector).count
          coll.find(selector).delete_many
          deleted
        end
      end
    end
  end
end
