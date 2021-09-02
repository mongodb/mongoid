# frozen_string_literal: true

module Rails
  module Mongoid
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
      app.config.paths["app/models"].expanded.each do |path|
        preload = ::Mongoid.preload_models
        if preload.resizable?
          files = preload.map { |model| "#{path}/#{model.underscore}.rb" }
        else
          files = Dir.glob("#{path}/**/*.rb")
        end

        files.sort.each do |file|
          load_model(file.gsub("#{path}/" , "").gsub(".rb", ""))
        end
      end
    end

    # Conditionally calls `Rails::Mongoid.load_models(app)` if the
    # `::Mongoid.preload_models` is `true`.
    #
    # @param [ Application ] app The rails application.
    def preload_models(app)
      load_models(app) if ::Mongoid.preload_models
    end

    private

    # I don't want to mock out kernel for unit testing purposes, so added this
    # method as a convenience.
    #
    # @example Load the model.
    #   Mongoid.load_model("/mongoid/behavior")
    #
    # @param [ String ] file The base filename.
    def load_model(file)
      begin
        require_dependency(file)
      rescue Exception => e
        Logger.new(STDERR).warn(e.message)
      end
    end
  end
end
