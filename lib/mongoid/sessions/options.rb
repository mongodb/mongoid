module Mongoid
  module Sessions
    module Options
      extend ActiveSupport::Concern

      # Tell the next persistance operation to store in a specific collection,
      # database or session.
      #
      # @example Save the current document to a different collection.
      #   model.with(collection: "secondary").save
      #
      # @example Save the current document to a different database.
      #   model.with(database: "secondary").save
      #
      # @example Save the current document to a different session.
      #   model.with(session: "replica_set").save
      #
      # @example Save with a combination of options.
      #   model.with(session: "sharded", database: "secondary").save
      #
      # @param [ Hash ] options The storage options.
      #
      # @option options [ String, Symbol ] :collection The collection name.
      # @option options [ String, Symbol ] :database The database name.
      # @option options [ String, Symbol ] :session The session name.
      #
      # @return [ Document ] The current document.
      #
      # @since 3.0.0
      def with(options)
        @persistence_options = options
        self
      end

      def persistence_options
        @persistence_options
      end

      module ClassMethods

        # Tell the next persistance operation to store in a specific collection,
        # database or session.
        #
        # @example Create a document in a different collection.
        #   Model.with(collection: "secondary").create(name: "test")
        #
        # @example Create a document in a different database.
        #   Model.with(database: "secondary").create(name: "test")
        #
        # @example Create a document in a different session.
        #   Model.with(session: "secondary").create(name: "test")
        #
        # @example Create with a combination of options.
        #   Model.with(session: "sharded", database: "secondary").create
        #
        # @param [ Hash ] options The storage options.
        #
        # @option options [ String, Symbol ] :collection The collection name.
        # @option options [ String, Symbol ] :database The database name.
        # @option options [ String, Symbol ] :session The session name.
        #
        # @return [ Class ] The model class.
        #
        # @since 3.0.0
        def with(options)
          Threaded.set_persistence_options(self, options)
          self
        end

        def persistence_options
          Threaded.persistence_options(self).tap do
            Threaded.clear_persistence_options(self)
          end
        end
      end
    end
  end
end
