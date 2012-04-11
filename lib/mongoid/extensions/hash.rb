# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Hash

      # Make a deep copy of the hash.
      #
      # @example Make a deep copy.
      #   { :test => "value" }._deep_copy
      #
      # @return [ Hash ] The deep copy.
      #
      # @since 2.4.0
      def _deep_copy
        copy = {}
        each_pair do |key, value|
          copy[key] = value._deep_copy
        end
        copy
      end

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
