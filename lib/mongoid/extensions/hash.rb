# encoding: utf-8
module Mongoid
  module Extensions
    module Hash

      # Get the id attribute from this hash, whether it's prefixed with an
      # underscore or is a symbol.
      #
      # @example Extract the id.
      #   { :_id => 1 }.extract_id
      #
      # @return [ Object ] The value of the id.
      #
      # @since 2.3.2
      def extract_id
        self["id"] || self["_id"] || self[:id] || self[:_id]
      end
    end
  end
end

::Hash.__send__(:include, Mongoid::Extensions::Hash)
