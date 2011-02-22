# encoding: utf-8
module Rails #:nodoc:
  module Mongoid #:nodoc:
    extend self

    # Use the application configuration to get every model and require it, so
    # that indexing and inheritance work in both development and production
    # with the same results.
    #
    # @example Load all the application models.
    #   Rails::Mongoid.load_models(app)
    #
    # @param [ Application ] app The rails application.
    def load_models(app)
      return unless ::Mongoid.preload_models
      app.config.paths["app/models"].each do |path|
        Dir.glob("#{path}/**/*.rb").sort.each do |file|
          load_model(file.gsub("#{path}/" , "").gsub(".rb", ""))
        end
      end
    end

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

    private

    # I don't want to mock out kernel for unit testing purposes, so added this
    # method as a convenience.
    #
    # @example Load the model.
    #   Mongoid.load_model("/mongoid/behaviour")
    #
    # @param [ String ] file The base filename.
    #
    # @since 2.0.0.rc.3
    def load_model(file)
      require_dependency(file)
    end
  end
end
