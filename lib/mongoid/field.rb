module Mongoid #:nodoc:
  class Field

    attr_reader \
      :default,
      :key,
      :name

    def initialize(name, options = {})
      @name = name
      @default = options[:default]
      @key = options[:key]
    end

    def key?
      @key ? key : false
    end

  end
end