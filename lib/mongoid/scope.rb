# encoding: utf-8
module Mongoid #:nodoc:
  class Scope #:nodoc:

    attr_reader :conditions, :extensions

    # Create the new +Scope+. If a block is passed in, this Scope will store
    # the block for future calls to #extend.
    #
    # Options:
    #
    # conditions: A +Hash+ of conditions.
    # block:      A +block+ of extension methods (optional)
    #
    def initialize(conditions = {}, &block)
      @conditions = conditions
      @extensions = Module.new(&block) if block_given?
    end

    def extend(criteria)
      @extensions ? criteria.extend(@extensions) : criteria
    end

  end
end

