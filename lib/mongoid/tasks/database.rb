# encoding: utf-8
module Mongoid
  module Tasks
    module Database
      extend self

      # Create indexes for each model given the provided globs and the class is
      # not embedded.
      #
      # @example Create all the indexes.
      #   Mongoid::Tasks::Database.create_indexes
      #
      # @return [ Array<Class> ] The indexed models.
      #
      # @since 2.1.0
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
      # @return Hash{Class => Array(Hash)} The list of undefined indexes by model.
      def undefined_indexes(models = ::Mongoid.models)
        undefined_by_model = {}

        models.each do |model|
          unless model.embedded?
            begin
              model.collection.indexes.each do |index|
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

      # Prints a list of undefined indexes to the logger.
      #
      # @example Print list of undefined indexes.
      #   Mongoid::Tasks::Database.list_undefined_indexes
      #
      # @return [ Hash{Class => Array(Hash)}] The models and undefined indexes that were listed.
      #
      # @since 5.2.0
      def list_undefined_indexes(models = ::Mongoid.models)
        undefined_indexes(models).each do |model, indexes|
          log_model_and_indexes(model, indexes)
        end
      end

      # Prints a list of indexes to the logger.
      #
      # @example Print list of indexes.
      #   Mongoid::Tasks::Database.list_indexes
      #
      # @return [ Array<Class> ] The models whose indices were listed.
      #
      # @since 5.2.0
      def list_indexes(models = ::Mongoid.models)
        models.each do |model|
          unless model.embedded?
            log_model_and_indexes(model, model.collection.indexes.to_a)
          end
        end
      end

      # Remove indexes that exist in the database but aren't specified on the
      # models.
      #
      # @example Remove undefined indexes.
      #   Mongoid::Tasks::Database.remove_undefined_indexes
      #
      # @return [ Hash{Class => Array(Hash)}] The list of indexes that were removed by model.
      #
      # @since 4.0.0
      def remove_undefined_indexes(models = ::Mongoid.models)
        undefined_indexes(models).each do |model, indexes|
          indexes.each do |index|
            key = index['key'].symbolize_keys
            collection = model.collection
            collection.indexes.drop_one(key)
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
      #
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

      private
      def logger
        Mongoid.logger
      end

      def log_model_and_indexes(model, indexes)
        logger.info "#{model}"
        logger.info "  (none)" if indexes.empty?
        indexes.each{ |index| logger.info "  #{index['name']}" }
      end
    end
  end
end
