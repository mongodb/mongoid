# encoding: utf-8
module Mongoid #:nodoc:
  class ComplexCriterion
    attr_accessor :key, :operator

    def initialize opts = {}
      @key, @operator = opts[:key], opts[:operator]
    end
  end
end
