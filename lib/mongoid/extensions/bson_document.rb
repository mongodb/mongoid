# frozen_string_literal: true

module Mongoid
  module Extensions
    # Adds behavior to BSON::Document.
    module BsonDocument
      # Make a deep copy of this document, preserving the BSON::Document type.
      #
      # Hash#__deep_copy__ returns a plain Hash, which causes field_was to
      # return a different type than the field getter when the stored attribute
      # is a BSON::Document.
      #
      # @example Make a deep copy of the document.
      #   doc.__deep_copy__
      #
      # @return [ BSON::Document ] The copied document.
      def __deep_copy__
        self.class.new.tap do |copy|
          each_pair do |key, value|
            copy.store(key, value.__deep_copy__)
          end
        end
      end
    end
  end
end

BSON::Document.include Mongoid::Extensions::BsonDocument
