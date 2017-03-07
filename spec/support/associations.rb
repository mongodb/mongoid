module Mongoid
  module Associations
    module SpecHelpers

      extend self

      EMBEDDED_ASSOCIATIONS = [
          Mongoid::Associations::Embedded::EmbedsMany,
          Mongoid::Associations::Embedded::EmbedsOne,
          Mongoid::Associations::Embedded::EmbeddedIn
      ].freeze

      STORES_FOREIGN_KEY = [
          Mongoid::Associations::Referenced::HasAndBelongsToMany,
          Mongoid::Associations::Referenced::BelongsTo
      ]

      def embedded_association?(association_class)
        EMBEDDED_ASSOCIATIONS.include?(association_class)
      end

      def supports_option?(association_class, option)
        association_class::VALID_OPTIONS.include?(option)
      end

      def stores_foreign_key?(association_class)
        STORES_FOREIGN_KEY.include?(association_class)
      end
    end
  end
end