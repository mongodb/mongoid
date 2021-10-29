# frozen_string_literal: true

module Mongoid

  # Contains the behavior around inspecting documents via inspect.
  module Inspectable

    # Returns the class name plus its attributes. If using dynamic fields will
    # include those as well.
    #
    # @example Inspect the document.
    #   person.inspect
    #
    # @return [ String ] A nice pretty string to look at.
    def inspect
      inspection = []
      inspection.concat(inspect_fields).concat(inspect_dynamic_fields)
      "#<#{self.class.name} _id: #{_id}, #{inspection * ', '}>"
    end

    private

    # Get an array of inspected fields for the document.
    #
    # @api private
    #
    # @example Inspect the defined fields.
    #   document.inspect_fields
    #
    # @return [ String ] An array of pretty printed field values.
    def inspect_fields
      fields.map do |name, field|
        unless name == "_id"
          as = field.options[:as]
          "#{name}#{as ? "(#{as})" : nil}: #{@attributes[name].inspect}"
        end
      end.compact
    end

    # Get an array of inspected dynamic fields for the document.
    #
    # @api private
    #
    # @example Inspect the dynamic fields.
    #   document.inspect_dynamic_fields
    #
    # @return [ String ] An array of pretty printed dynamic field values.
    def inspect_dynamic_fields
      []
    end
  end
end
