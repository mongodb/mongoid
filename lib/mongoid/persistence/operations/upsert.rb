# encoding: utf-8
module Mongoid
  module Persistence
    module Operations

      # Wraps behaviour for performing upserts in Mongodb. No matter if the
      # document has been modified or not, it will be sent to the db and Mongo
      # will determin whether or not to insert or update.
      class Upsert
        include Upsertion, Operations

        # Persist the upsert operation.
        #
        # @example Execute the upsert.
        #   operation.persist
        #
        # @return [ true ] Always true.
        #
        # @since 3.0.0
        def persist
          prepare do
            collection.find(selector).update(document.as_document, [ :upsert ])
          end
        end
      end
    end
  end
end
