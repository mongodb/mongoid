# encoding: utf-8
module Mongoid #:nodoc:
  class Field

    attr_reader \
      :default,
      :name,
      :type

    # Create the new field with a name and optional additional options. Valid
    # options are :default
    #
    # Options:
    #
    # name: The name of the field as a +Symbol+.
    # options: A +Hash+ of options for the field.
    #
    # Example:
    #
    # <tt>Field.new(:score, :default => 0)</tt>
    def initialize(name, options = {})
      @name = name
      @default = options[:default]
      @type = options[:type] || String
    end

    # Used for setting an object in the attributes hash. If nil is provided the
    # default will get returned if it exists.
    def set(object)
      object.nil? ? default : type.set(object)
    end

    # Used for retrieving the object out of the attributes hash.
    def get(object)
      type.get(object)
    end

  end
end
