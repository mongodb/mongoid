# encoding: utf-8
module Mongoid
  module Atomic

    # This module is responsible for taking update selectors and switching out
    # the indexes for the $ positional operator where appropriate.
    #
    # @since 3.1.0
    module Positionable

      # Takes the provided selector and atomic operations and replaces the
      # indexes of the embedded documents with the positional operator when
      # needed.
      #
      # @note The only time we can accurately know when to use the positional
      #   operator is at the exact time we are going to persist something. So
      #   we can tell by the selector that we are sending if it is actually
      #   possible to use the positional operator at all. For example, if the
      #   selector is: { "_id" => 1 }, then we could not use the positional
      #   operator for updating embedded documents since there would never be a
      #   match - we base whether we can based on the number of levels deep the
      #   selector goes, and if the id values are not nil.
      #
      # @example Process the operations.
      #   positionally(
      #     { "_id" => 1, "addresses._id" => 2 },
      #     { "$set" => { "addresses.0.street" => "hobrecht" }}
      #   )
      #
      # @param [ Hash ] selector The selector.
      # @param [ Hash ] operations The update operations.
      # @param [ Hash ] processed The processed update operations.
      #
      # @return [ Hash ] The new operations.
      #
      # @since 3.1.0
      def positionally(selector, operations, processed = {})
        if selector.size == 1 || selector.values.any? { |val| val.nil? }
          return operations
        end
        process_operations(selector.size - 2, operations, processed)
      end

      private

      def process_operations(index, operations, processed)
        operations.each_pair do |operation, update|
          processed[operation] = process_updates(index, update)
        end
        processed
      end

      def process_updates(index, update, updates = {})
        update.each_pair do |position, value|
          updates[replace_index(position, index)] = value
        end
        updates
      end

      def replace_index(position, index, counter = 0)
        position.gsub(/(\.\w+\.)/) do |match|
          value = (counter == index && match[1, match.length - 2] =~ /\d+/) ? ".$." : match
          counter += 1
          value
        end
      end
    end
  end
end
