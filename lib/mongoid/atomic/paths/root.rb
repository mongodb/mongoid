# frozen_string_literal: true

module Mongoid
  module Atomic
    module Paths

      # This class encapsulates behavior for locating and updating root
      # documents atomically.
      class Root

        attr_reader :document, :path, :position

        # Create the new root path utility.
        #
        # @example Create the root path util.
        #   Root.new(document)
        #
        # @param [ Document ] document The document to generate the paths for.
        def initialize(document)
          @document, @path, @position = document, "", ""
        end

        # Asking for the insert modifier on a document with a root path
        # indicates a mixed association most likely happened.
        #
        # @example Attempt to get the insert modifier.
        #   root.insert_modifier
        #
        # @raise [ Errors::InvalidPath ] The error for the attempt.
        def insert_modifier
          raise Errors::InvalidPath.new(document.class)
        end
      end
    end
  end
end
