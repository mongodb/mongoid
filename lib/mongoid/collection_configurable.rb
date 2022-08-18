# frozen_string_literal: true

module Mongoid

  # Encapsulates behavior around defining collections.
  module CollectionConfigurable
    extend ActiveSupport::Concern

    module ClassMethods
      def create_collection
        if coll_options = collection.database.list_collections(filter: { name: collection_name.to_s }).first
          logger.info(
            "MONGOID: Collection '#{collection_name}' already exist " +
            "in database '#{database_name}' with options '#{coll_options}'."
          )
        else
          begin
            collection.database[collection_name].create(storage_options[:collection_options])
          rescue Mongo::Error::OperationFailure => e
            raise Errors::CreateCollection.new(
              collection_name,
              storage_options[:collection_options],
              e
            )
          end
        end
      end
    end
  end
end
