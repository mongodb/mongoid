# frozen_string_literal: true
# rubocop:todo all

module Mongoid

  # Defines how Mongoid can autoload all defined models.
  module Loadable
    # The default list of paths where model classes should be looked for. If
    # Rails is present, the "app/models" paths will be used instead.
    # (See #model_paths.)
    DEFAULT_MODEL_PATHS = %w( ./app/models ./lib/models ).freeze

    # Search a list of model paths to get every model and require it, so
    # that indexing and inheritance work in both development and production
    # with the same results.
    #
    # @example Load all the application models from default model paths.
    #   Mongoid.load_models
    #
    # @example Load all application models from a non-standard set of paths.
    #   Mongoid.load_models(%w( ./models ./admin/models ))
    #
    # @param [ Array ] paths The list of paths that should be looked in
    #   for model files. These must either be absolute paths, or relative to
    #   the current working directory.
    def load_models(paths = model_paths)
      paths.each do |path|
        if preload_models.resizable?
          files = preload_models.map { |model| "#{path}/#{model.underscore}.rb" }
        else
          files = Dir.glob("#{path}/**/*.rb")
        end

        files.sort.each do |file|
          load_model(file.gsub(/^#{path}\// , "").gsub(/\.rb$/, ""))
        end
      end
    end

    # A convenience method for loading a model's file. If Rails'
    # `require_dependency` method exists, it will be used; otherwise
    # `require` will be used.
    #
    # @example Load the model.
    #   Mongoid.load_model("/mongoid/behavior")
    #
    # @param [ String ] file The base filename.
    #
    # @api private
    def load_model(file)
      if defined?(require_dependency)
        require_dependency(file)
      else
        require(file)
      end
    end

    # Returns the array of paths where the application's model definitions
    # are located. If Rails is loaded, this defaults to the configured
    # "app/models" paths (e.g. `config.paths["app/models"]`); otherwise, it
    # defaults to `%w(./app/models ./lib/models)`.
    #
    # Note that these paths are the *roots* of the directory hierarchies where
    # the models are located; it is not necessary to indicate every subdirectory,
    # as long as these root paths are located in `$LOAD_PATH`.
    #
    # @return [ Array<String> ] the array of model paths
    def model_paths
      @model_paths ||= defined?(Rails) ?
        Rails.application.config.paths["app/models"].expanded :
        DEFAULT_MODEL_PATHS
    end

    # Sets the model paths to the given array of paths. These are the paths
    # where the application's model definitions are located.
    #
    # @param [ Array<String> ] paths The list of model paths
    def model_paths=(paths)
      @model_paths = paths
    end
  end

end
