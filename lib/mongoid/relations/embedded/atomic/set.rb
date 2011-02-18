# encoding: utf-8
module Mongoid #:nodoc:
  module Relations #:nodoc:
    module Embedded #:nodoc:
      module Atomic #:nodoc:

        class Set
          attr_accessor :documents, :options, :path, :selector

          # Consumes an execution that was supposed to hit the database, but is
          # now being deferred to later in favor of a single update.
          #
          # @example Consume the operation.
          #   set.consume(
          #     { "_id" => BSON::ObjectId.new },
          #     { "addresses" => { "$pushAll" => [{ "_id" => "street" }] } },
          #     { :multi => false, :safe => true }
          #   )
          #
          # @param [ Hash ] selector The document selector.
          # @param [ Hash ] operations The ops to set in the db.
          # @param [ Hash ] options The persistence options.
          #
          # @option options [ true, false ] :multi Persist multiple at once.
          # @option options [ true, false ] :safe Persist in safe mode.
          #
          # @since 2.0.0
          def consume(selector, operations, options = {})
            @consumed, @selector, @options = true, selector, options
            @documents ||= []
            parse(operations)
          end

          def consumed?
            !!@consumed
          end

          def execute(collection)
            collection.update(selector, operations, options) if consumed?
          end

          # Get the merged operations for the single atomic set.
          #
          # @example Get the operations
          #   set.operations
          #
          # @return [ Hash ] The set operations.
          #
          # @since 2.0.0
          def operations
            { "$set" => { path => documents } }
          end

          private

          # Parses the incoming operations to get the documents to set.
          #
          # @example Parse the operations.
          #   set.parse(
          #     { "addresses" => { "$pushAll" => [{ "_id" => "street" }] } }
          #   )
          #
          # @param [ Hash ] operations The ops to parse.
          #
          # @since 2.0.0
          def parse(operations)
            modifier = operations.keys.first
            extract(modifier, operations[modifier])
          end

          # Extract a document from the operation.
          #
          # @example Extract the document.
          #   set.extract({ "$pushAll" => [{ "_id" => "street" }] })
          #
          # @param [ Hash ] operation The op to extract from.
          #
          # @since 2.0.0
          def extract(modifier, operations)
            @path = operations.keys.first
            case modifier
            when "$push"
              documents.push(operations[path])
            when "$pushAll"
              documents.push(operations[path].first)
            when "$set"
              @documents = operations[path]
            end
          end
        end
      end
    end
  end
end
