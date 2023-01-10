# frozen_string_literal: true

module Mongoid
  module Persistable

    # Defines behavior for setting a field (or fields) to the current
    # date/time.
    module Datable
      extend ActiveSupport::Concern

      # Converts the argument into the appropriate $currentDate type.
      #
      # @param [ nil | String | Symbol | Hash ] type The type description
      #   to translate.
      #
      # @return [ true | Hash ] The type description indicated by the argument.
      #
      # @api private
      def self.translate_date_field_spec(type)
        case type
        # `current_date(:foo)` == `current_date(foo: true)`
        when nil then true
        when "timestamp", :timestamp, "date", :date
          { "$type" => type.to_s }
        else type
        end
      end
      
      # Set the given field or fields to the current date/time.
      #
      # @example Set a field to the current date.
      #   document.current_date(:updated)
      #   # or
      #   document.current_date(updated: true)
      #   # or
      #   document.current_date(updated: :date)
      #
      # @example Set multiple fields to the current date, in different formats:
      #   document.current_date(:updated, { founded: true, touched: :timestamp })
      #
      # @param [ Array<Array | Hash | Symbol | String> ] specs The fields to
      #   set to the current date/time.
      #
      # @return [ Document ] The document.
      def current_date(*specs)
        prepare_atomic_operation do |ops|
          specs.each do |spec|
            process_atomic_operations(Array(spec)) do |field, value|
              value = Datable.translate_date_field_spec(value)
              process_attribute field, DateTime.now
              ops[atomic_attribute_name(field)] = value
            end
          end
          { "$currentDate" => ops }
        end
      end
    end
  end
end
