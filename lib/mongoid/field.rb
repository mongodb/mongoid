module Mongoid #:nodoc:
  class Field

    attr_reader \
      :default,
      :key,
      :name

    # Create the new field with a name and optional additional options. Valid
    # options are :default, :key
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
      @key = options[:key]
    end

    # Returns true if this field acts as a primary key.
    def key?
      @key ? key : false
    end

  end
end
