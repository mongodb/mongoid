# encoding: utf-8
module Mongoid
  module Timestamps
    module Macros
      extend ActiveSupport::Concern

      module ClassMethods

        # timestamps
        # timestamps :both
        # timestamps both: :short
        # timestamps :created
        # timestamps :updated
        # timestamps :short
        # timestamps created: :short
        # timestamps updated: :short
        # timestamps created: true
        # timestamps updated: true
        # timestamps both: true
        def timestamps(options = :both)
          options = { options => true } if options.is_a?(Symbol)

          created_option = options.values_at(:created, :both)
          updated_option = options.values_at(:updated, :both)

          include Created if created_option.include?(true)
          include Updated if updated_option.include?(true)
          include Created::Short if created_option.include?(:short) || options[:short]
          include Updated::Short if updated_option.include?(:short) || options[:short]
        end
      end
    end
  end
end
