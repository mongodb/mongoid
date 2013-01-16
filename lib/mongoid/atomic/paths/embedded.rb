# encoding: utf-8
require "mongoid/atomic/paths/embedded/one"
require "mongoid/atomic/paths/embedded/many"

module Mongoid
  module Atomic
    module Paths

      # Common functionality between the two different embedded paths.
      module Embedded

        attr_reader :delete_modifier, :document, :insert_modifier, :parent

        # Get the path to the document in the hierarchy.
        #
        # @example Get the path.
        #   many.path
        #
        # @return [ String ] The path to the document.
        #
        # @since 2.1.0
        def path
          position.sub(/\.\d+$/, "")
        end

        # Get the selector to use for the root document when performing atomic
        # updates. When sharding this will include the shard key.
        #
        # @example Get the selector.
        #   many.selector
        #
        # @return [ Hash ] The selector to identify the document with.
        #
        # @since 2.1.0
        def selector
          if only_root_selector?
            parent.atomic_selector
          else
            parent.
              atomic_selector.
              merge("#{path}._id" => document._id).
              merge(document.shard_key_selector)
          end
        end

        # Gets the selector used to determine the exact embedded document to
        # update.
        #
        # @example Get the update selector.
        #   embedded.update_selector
        #
        # @note This replaces the first found index with the $ positional
        #   operator since it does work at least 1 level deep.
        #
        # @return [ String ] The update selector.
        #
        # @since 3.1.0
        def update_selector
          if positionally_operable?
            position.sub(/\.\d/, ".$")
          else
            position
          end
        end

        private

        def only_root_selector?
          document.persisted? && document._id_changed?
        end

        def positionally_operable?
          !document._root.updates_requested? && !only_root_selector?
        end
      end
    end
  end
end
