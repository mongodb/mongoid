# frozen_string_literal: true

module Mongoid
  module Attributes
    # Utility module for working with embedded attributes.
    module Embedded
      extend self

      # Fetch an embedded value or subset of attributes via dot notation.
      #
      # @example Fetch an embedded value via dot notation.
      #   Embedded.traverse({ 'name' => { 'en' => 'test' } }, 'name.en')
      #   #=> 'test'
      #
      # @param [ Hash ] attributes The document attributes.
      # @param [ String ] path The dot notation string.
      #
      # @return [ Object | nil ] The attributes at the given path,
      #   or nil if the path doesn't exist.
      def traverse(attributes, path)
        path.split('.').each do |key|
          break if attributes.nil?

          attributes = if attributes.try(:key?, key)
                         attributes[key]
                       elsif attributes.respond_to?(:each) && key.match?(/\A\d+\z/)
                         attributes[key.to_i]
                       end
        end
        attributes
      end
    end
  end
end
