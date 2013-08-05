# encoding: utf-8
module Rails
  module Mongoid
    extend self

    # Create indexes for each model given the provided globs and the class is
    # not embedded.
    #
    # @example Create all the indexes.
    #   Rails::Mongoid.create_indexes
    #
    # @return [ Array<Class> ] The indexed models.
    #
    # @since 2.1.0
    def create_indexes
      ::Mongoid.models.each do |model|
        next if model.index_specifications.empty?
        unless model.embedded?
          model.create_indexes
          logger.info("MONGOID: Created indexes on #{model}:")
          model.index_specifications.each do |spec|
            logger.info("MONGOID: Index: #{spec.key}, Options: #{spec.options}")
          end
          model
        else
          logger.info("MONGOID: Index ignored on: #{model}, please define in the root model.")
          nil
        end
      end.compact
    end

    # Return the list of indexes by model that exist in the database but aren't
    # specified on the models.
    #
    # @example Return the list of unused indexes.
    #   Rails::Mongoid.undefined_indexes
    #
    # @return Hash{Class => Array(Hash)} The list of undefined indexes by model.
    def undefined_indexes
      undefined_by_model = {}

      ::Mongoid.models.each do |model|
        unless model.embedded?
          model.collection.indexes.each do |index|
            # ignore default index
            unless index['name'] == '_id_'
              key = index['key'].symbolize_keys
              spec = model.index_specification(key)
              unless spec
                # index not specified
                undefined_by_model[model] ||= []
                undefined_by_model[model] << index
              end
            end
          end
        end
      end

      undefined_by_model
    end

    # Remove indexes that exist in the database but aren't specified on the
    # models.
    #
    # @example Remove undefined indexes.
    #   Rails::Mongoid.remove_undefined_indexes
    #
    # @return [ Hash{Class => Array(Hash)}] The list of indexes that were removed by model.
    #
    # @since 4.0.0
    def remove_undefined_indexes
      undefined_indexes.each do |model, indexes|
        indexes.each do |index|
          key = index['key'].symbolize_keys
          model.collection.indexes.drop(key)
          logger.info("MONGOID: Removing index: #{index['name']} on #{model}.")
        end
      end
    end

    # Remove indexes for each model given the provided globs and the class is
    # not embedded.
    #
    # @example Remove all the indexes.
    #   Rails::Mongoid.remove_indexes
    #
    # @return [ Array<Class> ] The un-indexed models.
    #
    def remove_indexes
      ::Mongoid.models.each do |model|
        next if model.embedded?
        indexes = model.collection.indexes.map{ |doc| doc["name"] }
        indexes.delete_one("_id_")
        model.remove_indexes
        logger.info("MONGOID: Removing indexes on: #{model} for: #{indexes.join(', ')}.")
        model
      end.compact
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
