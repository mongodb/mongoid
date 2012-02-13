# encoding: utf-8
module Rails #:nodoc:
  module Mongoid #:nodoc:
    extend self

    # Create indexes for each model given the provided pattern and the class is
    # not embedded.
    #
    # @example Create all the indexes.
    #   Rails::Mongoid.create_indexes("app/models/**/*.rb")
    #
    # @param [ String ] pattern The file matching pattern.
    #
    # @return [ Array<String> ] The file names.
    #
    # @since 2.1.0
    def create_indexes(pattern)
      Dir.glob(pattern).each do |file|
        logger = Logger.new($stdout)
        begin
          model = determine_model(file, logger)
        rescue => e
          logger.error(%Q{Failed to determine model from #{file}:
            #{e.class}:#{e.message}
            #{e.backtrace.join("\n")}
          })
        end
        if model
          model.create_indexes
          logger.info("Generated indexes for #{model}")
        else
          logger.info("Not a Mongoid parent model: #{file}")
        end
      end
    end

    # Use the application configuration to get every model and require it, so
    # that indexing and inheritance work in both development and production
    # with the same results.
    #
    # @example Load all the application models.
    #   Rails::Mongoid.load_models(app)
    #
    # @param [ Application ] app The rails application.
    def load_models(app)
      app.config.paths["app/models"].each do |path|
        Dir.glob("#{path}/**/*.rb").sort.each do |file|
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
    #   Mongoid.load_model("/mongoid/behaviour")
    #
    # @param [ String ] file The base filename.
    #
    # @since 2.0.0.rc.3
    def load_model(file)
      require_dependency(file)
    end

    # Given the provided file name, determine the model and return the class.
    #
    # @example Determine the model from the file.
    #   Rails::Mongoid.determine_model("app/models/person.rb")
    #
    # @param [ String ] file The filename.
    #
    # @return [ Class ] The model.
    #
    # @since 2.1.0
    def determine_model(file, logger)
      if file =~ /app\/models\/(.*).rb$/
        model_path = $1.split('/')
        begin
          parts = model_path.map { |path| path.camelize }
          name = parts.join("::")
          klass = name.constantize
        rescue NameError, LoadError => e
          logger.info("Attempted to constantize #{name}, trying without namespacing.")
          klass = parts.last.constantize
        end
        if klass.ancestors.include?(::Mongoid::Document) && !klass.embedded
          return klass
        end
      end
    end
  end
end
