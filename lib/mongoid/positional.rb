# frozen_string_literal: true

module Mongoid

  # This module is responsible for taking update selectors and switching out
  # the indexes for the $ positional operator where appropriate.
  module Positional

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
    def positionally(selector, operations, processed = {})
      if selector.size == 1 || selector.values.any? { |val| val.nil? }
        return operations
      end
      keys = selector.keys.map{ |m| m.sub('._id','') } - ['_id']
      keys = keys.sort_by { |s| s.length*-1 }
      process_operations(keys, operations, processed)
    end

    private

    def process_operations(keys, operations, processed)
      operations.each_pair do |operation, update|
        processed[operation] = process_updates(keys, update)
      end
      processed
    end

    def process_updates(keys, update, updates = {})
      update.each_pair do |position, value|
        updates[replace_index(keys, position)] = value
      end
      updates
    end

    def replace_index(keys, position)
      # replace index with $ only if that key is in the selector and it is only
      # nested a single level deep.
      matches = position.scan(/\.\d+\./)
      if matches.size == 1
        keys.each do |kk|
          if position =~ /\A#{kk}\.\d+\.(.*)\z/
            return "#{kk}.$.#{$1}"
          end
        end
      end
      position
    end
  end
end
