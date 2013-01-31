# encoding: utf-8
module Rails
  module Mongoid
    extend self

    # Create indexes for each model given the provided globs and the class is
    # not embedded.
    #
    # @example Create all the indexes.
    #   Rails::Mongoid.create_indexes("app/models/**/*.rb")
    #
    # @param [ Array<String> ] globs The file matching globs.
    #
    # @return [ Array<Class> ] The indexed models.
    #
    # @since 2.1.0
    def create_indexes(*globs)
      models(*globs).each do |model|
        next if model.index_options.empty?
        unless model.embedded?
          model.create_indexes
          logger.info("MONGOID: Created indexes on #{model}:")
          model.index_options.each_pair do |index, options|
            logger.info("MONGOID: Index: #{index}, Options: #{options}")
          end
          model
        else
          logger.info("MONGOID: Index ignored on: #{model}, please define in the root model.")
          nil
        end
      end.compact
    end

    # Remove indexes for each model given the provided globs and the class is
    # not embedded.
    #
    # @example Remove all the indexes.
    #   Rails::Mongoid.create_indexes("app/models/**/*.rb")
    #
    # @param [ Array<String> ] globs The file matching globs.
    #
    # @return [ Array<Class> ] The un-indexed models.
    #
    def remove_indexes(*globs)
      models(*globs).each do |model|
        next if model.embedded?
        indexes = model.collection.indexes.map{ |doc| doc["name"] }
        indexes.delete_one("_id_")
        model.remove_indexes
        logger.info("MONGOID: Removing indexes on: #{model} for: #{indexes.join(', ')}.")
        model
      end.compact
    end

    # Return all models matching the globs or, if no globs are specified, all
    # possible models known from engines, the app, any gems, etc.
    #
    # @example Return *all* models.  Return all models under app/models/
    #   Rails::Mongoid.models
    #   Rails::Mongoid.models("app/models/**/*.rb")
    #
    # @param [ String ] glob The file matching glob.
    #
    # @return [ Array<Class> ] The models.
    #
    def models(*globs)
      all_possible_models = globs.empty?

      if globs.empty?
        engines_models_paths = Rails.application.railties.engines.map{|engine| engine.paths["app/models"].expanded}
        root_models_paths = Rails.application.paths["app/models"]
        models_paths = engines_models_paths.push(root_models_paths).flatten
        globs.replace(models_paths.map{|path| "#{path}/**/*.rb"})
      end

      models = []

      globs.flatten.compact.each do |glob|
        Dir.glob(glob).map do |file|
          begin
            model = determine_model(file, logger)
            models.push(model)
          rescue => e
            logger.error(%Q{MONGOID: Failed to determine model from #{file}:
              #{e.class}:#{e.message}
              #{e.backtrace.join("\n")}
            })
            nil
          end
        end
      end

      models = (::Mongoid.models | models) if all_possible_models

      models.compact.sort_by { |model| model.name || '' }
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
        preload = ::Mongoid.preload_models
        if preload.resizable?
          files = preload.map { |model| "#{path}/#{model}.rb" }
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
    #   Mongoid.load_model("/mongoid/behaviour")
    #
    # @param [ String ] file The base filename.
    #
    # @since 2.0.0.rc.3
    def load_model(file)
      begin
        require_dependency(file)
      rescue Exception => e
        Logger.new($stdout).warn(e.message)
      end
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
        logger.info("MONGOID: Attempted to constantize #{name}, trying without namespacing.")
        klass = parts.last.constantize rescue nil
      end
      klass if klass && klass.ancestors.include?(::Mongoid::Document)
    end

    def logger
      @logger ||= Logger.new($stdout)
    end
  end
end
