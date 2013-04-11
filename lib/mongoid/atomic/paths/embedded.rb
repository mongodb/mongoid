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
      end
    end
  end
end
