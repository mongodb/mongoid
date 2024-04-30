# frozen_string_literal: true
# rubocop:todo all

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

    # This pretty prints the same information as the inspect method. This is
    # meant to be called by the standard 'pp' library.
    #
    # @param [ PP ] pretty_printer The pretty printer.
    #
    # @example Pretty print the document.
    #   person.pretty_inspect
    #
    # @api private
    def pretty_print(pretty_printer)
      keys = fields.keys | attributes.keys
      pretty_printer.group(1, "#<#{self.class.name}", '>') do
        sep = lambda { pretty_printer.text(',') }
        pretty_printer.seplist(keys, sep) do |key|
          pretty_printer.breakable
          field = fields[key]
          as = "(#{field.options[:as]})" if field && field.options[:as]
          pretty_printer.text("#{key}#{as}")
          pretty_printer.text(':')
          pretty_printer.group(1) do
            pretty_printer.breakable
            if key == "_id"
              pretty_printer.text(_id.to_s)
            else
              pretty_printer.pp(@attributes[key])
            end
          end
        end
      end
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
