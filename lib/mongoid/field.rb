module Mongoid #:nodoc:
  class Field

    attr_reader :name, :default

    def initialize(name, options = {})
      @name = name
      @default = options[:default]
    end

  end
end