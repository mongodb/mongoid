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
          @path ||= position.sub(/\.\d+$/, "")
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
          @selector ||= generate_selector
        end

        private

        def generate_selector
          if only_root_selector?
            parent.atomic_selector
          else
            parent.
              atomic_selector.
              merge("#{path}._id" => document._id).
              merge(document.shard_key_selector)
          end
        end

        def only_root_selector?
          document.persisted? && document._id_changed?
        end
      end
    end
  end
end
