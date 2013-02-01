# encoding: utf-8
module Mongoid
  module Atomic
    module Paths

      # This class encapsulates behaviour for locating and updating root
      # documents atomically.
      class Root

        attr_reader :document, :path, :position

        # Create the new root path utility.
        #
        # @example Create the root path util.
        #   Root.new(document)
        #
        # @param [ Document ] document The document to generate the paths for.
        #
        # @since 2.1.0
        def initialize(document)
          @document, @path, @position = document, "", ""
        end

        # Asking for the insert modifier on a document with a root path
        # indicates a mixed relation most likely happened.
        #
        # @example Attempt to get the insert modifier.
        #   root.insert_modifier
        #
        # @raise [ Errors::InvalidPath ] The error for the attempt.
        #
        # @since 3.0.14
        def insert_modifier
          raise Errors::InvalidPath.new(document.class)
        end

        # Get the selector to use for the root document when performing atomic
        # updates. When sharding this will include the shard key.
        #
        # @example Get the selector.
        #   root.selector
        #
        # @return [ Hash ] The selector to identify the document with.
        #
        # @since 2.1.0
        def selector
          @selector ||= { "_id" => document._id }.merge!(document.shard_key_selector)
        end
      end
    end
  end
end
