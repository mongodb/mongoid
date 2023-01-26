# frozen_string_literal: true

module Mongoid
  module Tasks
    module Database
      extend self

      # Create collections for each model given the provided globs and the class is
      # not embedded.
      #
      # @param [ Array<Mongoid::Document> ] models. Array of document classes for
      #   which collections should be created. Defaulted to all document classes
      #   in the application.
      # @param [ true | false ] force If true, the method will drop existing
      #   collections before creating new ones. If false, the method will create
      #   only new collection (that do not exist in the database).
      def create_collections(models = ::Mongoid.models, force: false)
        models.each do |model|
          if !model.embedded? || model.cyclic?
            model.create_collection(force: force)
            logger.info("MONGOID: Created collection for #{model}:")
          else
            logger.info("MONGOID: collection options ignored on: #{model}, please define in the root model.")
          end
        end
      end

      # Create indexes for each model given the provided globs and the class is
      # not embedded.
      #
      # @example Create all the indexes.
      #   Mongoid::Tasks::Database.create_indexes
      #
      # @return [ Array<Class> ] The indexed models.
      def create_indexes(models = ::Mongoid.models)
        models.each do |model|
          next if model.index_specifications.empty?
          if !model.embedded? || model.cyclic?
            model.create_indexes
            logger.info("MONGOID: Created indexes on #{model}:")
            model.index_specifications.each do |spec|
              logger.info("MONGOID: Index: #{spec.key}, Options: #{spec.options}")
            end
            model
          else
            logger.info("MONGOID: Index ignored on: #{model}, please define in the root model.")
            nil
          end
        end.compact
      end

      # Return the list of indexes by model that exist in the database but aren't
      # specified on the models.
      #
      # @example Return the list of unused indexes.
      #   Mongoid::Tasks::Database.undefined_indexes
      #
      # @return [ Array<Hash> ] The list of undefined indexes by model.
      def undefined_indexes(models = ::Mongoid.models)
        undefined_by_model = {}

        models.each do |model|
          unless model.embedded?
            begin
              model.collection.indexes(session: model.send(:_session)).each do |index|
                # ignore default index
                unless index['name'] == '_id_'
                  key = index['key'].symbolize_keys
                  spec = model.index_specification(key, index['name'])
                  unless spec
                    # index not specified
                    undefined_by_model[model] ||= []
                    undefined_by_model[model] << index
                  end
                end
              end
            rescue Mongo::Error::OperationFailure; end
          end
        end

        undefined_by_model
      end

      # Remove indexes that exist in the database but aren't specified on the
      # models.
      #
      # @example Remove undefined indexes.
      #   Mongoid::Tasks::Database.remove_undefined_indexes
      #
      # @return [ Hash{Class => Array(Hash)}] The list of indexes that were removed by model.
      def remove_undefined_indexes(models = ::Mongoid.models)
        undefined_indexes(models).each do |model, indexes|
          indexes.each do |index|
            key = index['key'].symbolize_keys
            collection = model.collection
            collection.indexes(session: model.send(:_session)).drop_one(key)
            logger.info(
              "MONGOID: Removed index '#{index['name']}' on collection " +
              "'#{collection.name}' in database '#{collection.database.name}'."
            )
          end
        end
      end

      # Remove indexes for each model given the provided globs and the class is
      # not embedded.
      #
      # @example Remove all the indexes.
      #   Mongoid::Tasks::Database.remove_indexes
      #
      # @return [ Array<Class> ] The un-indexed models.
      def remove_indexes(models = ::Mongoid.models)
        models.each do |model|
          next if model.embedded?
          begin
            model.remove_indexes
          rescue Mongo::Error::OperationFailure
            next
          end
          model
        end.compact
      end

      # Shard collections for models that declare shard keys.
      #
      # Returns the model classes that have had their collections sharded,
      # including model classes whose collections had already been sharded
      # prior to the invocation of this method.
      #
      # @example Shard all collections
      #   Mongoid::Tasks::Database.shard_collections
      #
      # @return [ Array<Class> ] The sharded models
      def shard_collections(models = ::Mongoid.models)
        models.map do |model|
          next if model.shard_config.nil?

          if model.embedded? && !model.cyclic?
            logger.warn("MONGOID: #{model} has shard config but is embedded")
            next
          end

          unless model.collection.cluster.sharded?
            logger.warn("MONGOID: #{model} has shard config but is not persisted in a sharded cluster: #{model.collection.cluster.summary}")
            next
          end

          # Database of the collection must exist in order to run collStats.
          # Depending on server version, the collection itself must also
          # exist.
          # MongoDB does not have a command to create the database; the best
          # approximation of it is to create the collection we want.
          # On older servers, creating a collection that already exists is
          # an error.
          # Additionally, 3.6 and potentially older servers do not provide
          # the error code when they are asked to collStats a non-existent
          # collection (https://jira.mongodb.org/browse/SERVER-50070).
          begin
            stats = model.collection.database.command(collStats: model.collection.name).first
          rescue Mongo::Error::OperationFailure => exc
            # Code 26 is database does not exist.
            # Code 8 is collection does not exist, as of 4.0.
            # On 3.6 and earlier match the text of exception message.
            if exc.code == 26 || exc.code == 8 ||
              exc.code.nil? && exc.message =~ /not found/
            then
              model.collection.create

              stats = model.collection.database.command(collStats: model.collection.name).first
            else
              raise
            end
          end

          stats = model.collection.database.command(collStats: model.collection.name).first
          if stats[:sharded]
            logger.info("MONGOID: #{model.collection.namespace} is already sharded for #{model}")
            next model
          end

          admin_db = model.collection.client.use(:admin).database

          begin
            admin_db.command(enableSharding: model.collection.database.name)
          rescue Mongo::Error::OperationFailure => exc
            # Server 2.6 fails if sharding is already enabled
            if exc.code == 23 || exc.code.nil? && exc.message =~ /already enabled/
              # Nothing
            else
              raise
            end
          end

          begin
            admin_db.command(shardCollection: model.collection.namespace, **model.shard_config)
          rescue Mongo::Error::OperationFailure => e
            logger.error("MONGOID: Failed to shard collection #{model.collection.namespace} for #{model}: #{e.class}: #{e}")
            next
          end

          logger.info("MONGOID: Sharded collection #{model.collection.namespace} for #{model}")

          model
        end.compact
      end

      private

      def logger
        Mongoid.logger
      end
    end
  end
end
