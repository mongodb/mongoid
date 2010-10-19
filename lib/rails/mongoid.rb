# encoding: utf-8
module Rails #:nodoc:
  module Mongoid #:nodoc:
    class << self

      # Use the application configuration to get every model and require it, so
      # that indexing and inheritance work in both development and production
      # with the same results.
      def load_models(app)
        app.config.paths['app/models'].each do |path|
          Dir.glob("#{path}/**/*.rb").sort.each do |file|
            require_dependency(file)
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
      def index_children(children)
        children.each do |model|
          Logger.new($stdout).info("Generating indexes for #{model}")
          model.create_indexes
          index_children(model.descendants)
        end
      end
    end
  end
end
