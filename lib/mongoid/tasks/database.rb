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
            model.collection.indexes.each do |index|
              # ignore default index
              unless index['name'] == '_id_'
                key = index['key'].symbolize_keys
                spec = model.index_specification(key)
                unless spec
                  # index not specified
                  undefined_by_model[model] ||= []
                  undefined_by_model[model] << index
                end
              end
            end
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
      #
      # @since 4.0.0
      def remove_undefined_indexes(models = ::Mongoid.models)
        undefined_indexes(models).each do |model, indexes|
          indexes.each do |index|
            key = index['key'].symbolize_keys
            model.collection.indexes.drop(key)
            logger.info("MONGOID: Removing index: #{index['name']} on #{model}.")
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
          indexes = model.collection.indexes.map{ |doc| doc["name"] }
          indexes.delete_one("_id_")
          model.remove_indexes
          logger.info("MONGOID: Removing indexes on: #{model} for: #{indexes.join(', ')}.")
          model
        end.compact
      end

      private
      def logger
        @logger ||= Logger.new($stdout)
      end
    end
  end
end
