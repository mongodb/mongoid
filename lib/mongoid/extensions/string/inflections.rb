# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module String #:nodoc:

      # This module contains convenience methods for string inflection and
      # conversion.
      module Inflections

        ActiveSupport::Inflector.inflections do |inflect|
          inflect.singular(/address$/, "address")
          inflect.singular("addresses", "address")
          inflect.irregular("canvas", "canvases")
        end

        REVERSALS = {
          "asc" => "desc",
          "ascending" => "descending",
          "desc" => "asc",
          "descending" => "ascending"
        }

        # Convert the string to a collection friendly name.
        #
        # @example Collectionize the string.
        #   "namespace/model".collectionize
        #
        # @return [ String ] The string in collection friendly form.
        def collectionize
          tableize.gsub("/", "_")
        end

        # Get the inverted sorting option.
        #
        # @example Get the inverted option.
        #   "asc".invert
        #
        # @return [ String ] The string inverted.
        def invert
          REVERSALS[self]
        end

        # Get the string as a getter string.
        #
        # @example Get the reader/getter
        #   "model=".reader
        #
        # @return [ String ] The string stripped of "=".
        def reader
          delete("=")
        end

        # Is this string a writer?
        #
        # @example Is the string a setter method?
        #   "model=".writer?
        #
        # @return [ true, false ] If the string contains "=".
        def writer?
          include?("=")
        end
      end
    end
  end
end
