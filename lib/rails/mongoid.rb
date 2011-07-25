# encoding: utf-8
module Rails #:nodoc:
  module Mongoid #:nodoc:
    extend self

    # Recursive function to create all the indexes for the model, then
    # potentially and subclass of the model since both are still root
    # documents in the hierarchy.
    #
    # Note there is a tricky naming scheme going on here that needs to be
    # revisisted. Module.descendants vs Class.descendents is way too
    # confusing.
    #
    # @example Index the children.
    #   Rails::Mongoid.index_children(classes)
    #
    # @param [ Array<Class> ] children The child model classes.
    def index_children(children)
      children.each do |model|
        Logger.new($stdout).info("Generating indexes for #{model}")
        model.create_indexes
        index_children(model.descendants)
      end
    end
  end
end
