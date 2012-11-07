# encoding: utf-8
module Rails
  module Mongoid
    extend self

    # Create indexes for each model given the provided pattern and the class is
    # not embedded.
    #
    # @example Create all the indexes.
    #   Rails::Mongoid.create_indexes("app/models/**/*.rb")
    #
    # @param [ String ] pattern The file matching pattern.
    #
    # @return [ Array<String> ] The file names.
    #
    # @since 2.1.0
    def create_indexes
      logger = Logger.new($stdout)
      Mongoid.models.each do |model|
        next if model.index_options.empty?
        unless model.embedded?
          model.create_indexes
          logger.info("MONGOID: Created indexes on #{model}:")
          model.index_options.each_pair do |index, options|
            logger.info("MONGOID: Index: #{index}, Options: #{options}")
          end
        else
          logger.info("MONGOID: Index ignored on: #{model}, please define in the root model.")
        end
      end
    end

    # Remove indexes for each model given the provided pattern and the class is
    # not embedded.
    #
    # @example Remove all the indexes.
    #   Rails::Mongoid.create_indexes("app/models/**/*.rb")
    #
    # @param [ String ] pattern The file matching pattern.
    #
    # @return [ Array<String> ] The file names.
    #
    def remove_indexes
      logger = Logger.new($stdout)
      Mongoid.models.each do |model|
        next if model.embedded?
        indexes = model.collection.indexes.map{ |doc| doc["name"] }
        indexes.delete_one("_id_")
        model.remove_indexes
        logger.info("MONGOID: Removing indexes on: #{model} for: #{indexes.join(', ')}.")
      end
    end
  end
end
