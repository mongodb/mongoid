# encoding: utf-8
module Mongoid

  # Contains the bahviour around inspecting documents via inspect.
  #
  # @since 4.0.0
  module Inspectable

    # Returns the class name plus its attributes. If using dynamic fields will
    # include those as well.
    #
    # @example Inspect the document.
    #   person.inspect
    #
    # @return [ String ] A nice pretty string to look at.
    #
    # @since 1.0.0
    def inspect
      inspection = []
      inspection.concat(inspect_fields).concat(inspect_dynamic_fields)
      "#<#{self.class.name} _id: #{id}, #{inspection * ', '}>"
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
    #
    # @since 1.0.0
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
    #
    # @since 1.0.0
    def inspect_dynamic_fields
      []
    end
  end
end
