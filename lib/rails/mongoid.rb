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
      logger = Logger.new($stdout)
      models(pattern).each do |model|
        next if model.index_options.empty?
        unless model.embedded?
          model.create_indexes
          logger.info("Creating indexes on: #{model} for: #{model.index_options.keys.join(", ")}.")
        else
          logger.info("Index ignored on: #{model}, please define in the root model.")
        end
      end
    end

    # Remove indexes for each model given the provided pattern and the class is
    # not embedded.
    #
    # @example Remove all the indexes.
    #   Rails::Mongoid.create_indexes("app/models/**/*.rb")
    #
    # @param [ String ] pattern The file matching pattern.
    #
    # @return [ Array<String> ] The file names.
    #
    def remove_indexes(pattern)
      logger = Logger.new($stdout)
      models(pattern).each do |model|
        next if model.embedded?
        indexes = model.collection.indexes.map{ |doc| doc["name"] }
        indexes.delete_one("_id_")
        model.remove_indexes
        logger.info("Removing indexes on: #{model} for: #{indexes.join(', ')}.")
      end
    end

    # Return all models matching the pattern.
    #
    # @example Return all models.
    #   Rails::Mongoid.models("app/models/**/*.rb")
    #
    # @param [ String ] pattern The file matching pattern.
    #
    # @return [ Array<Class> ] The models.
    #
    def models(pattern)
      Dir.glob(pattern).map do |file|
        logger = Logger.new($stdout)
        begin
          determine_model(file, logger)
        rescue => e
          logger.error(%Q{Failed to determine model from #{file}:
            #{e.class}:#{e.message}
            #{e.backtrace.join("\n")}
          })
          nil
        end
      end.flatten.compact
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
      return nil unless file =~ /app\/models\/(.*).rb$/
      return nil unless logger

      model_path = $1.split('/')
      begin
        parts = model_path.map { |path| path.camelize }
        name = parts.join("::")
        klass = name.constantize
      rescue NameError, LoadError
        logger.info("Attempted to constantize #{name}, trying without namespacing.")
        klass = parts.last.constantize
      end
      klass if klass.ancestors.include?(::Mongoid::Document)
    end
  end
end
