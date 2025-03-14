# frozen_string_literal: true
# rubocop:todo all

module Mongoid

  # Defines how Mongoid can autoload all defined models.
  module Loadable
    # The default list of paths where model classes should be looked for. If
    # Rails is present, the "app/models" paths will be used instead.
    # (See #model_paths.)
    DEFAULT_MODEL_PATHS = %w( ./app/models ./lib/models ).freeze

    # The default list of glob patterns that match paths to ignore when loading
    # models. Defaults to '*/models/concerns/*', which Rails uses for extensions
    # to models (and which cause errors when loaded out of order).
    #
    # See #ignore_patterns.
    DEFAULT_IGNORE_PATTERNS = %w( */models/concerns/* ).freeze

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
      files = files_under_paths(paths)

      files.sort.each do |file|
        load_model(file)
      end

      nil
    end

    # Given a list of paths, return all ruby files under that path (or, if
    # `preload_models` is a list of model names, returns only the files for
    # those named models).
    #
    # @param [ Array<String> ] paths the list of paths to search
    #
    # @return [ Array<String> ] the normalized file names, suitable for loading
    #   via `require_dependency` or `require`.
    def files_under_paths(paths)
      paths.flat_map { |path| files_under_path(path) }
    end

    # Given a single path, returns all ruby files under that path (or, if
    # `preload_models` is a list of model names, returns only the files for
    # those named models).
    #
    # @param [ String ] path the path to search
    #
    # @return [ Array<String> ] the normalized file names, suitable for loading
    #   via `require_dependency` or `require`.
    def files_under_path(path)
      files = if preload_models.resizable?
          preload_models.
            map { |model| "#{path}/#{model.underscore}.rb" }.
            select { |file_name| File.exists?(file_name) }
        else
          Dir.glob("#{path}/**/*.rb").
            reject { |file_name| ignored?(file_name) }
        end

      # strip the path and the suffix from each entry
      files.map { |file| file.gsub(/^#{path}\// , "").gsub(/\.rb$/, "") }
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
    # "app/models" paths (e.g. 'config.paths["app/models"]'); otherwise, it
    # defaults to '%w(./app/models ./lib/models)'.
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

    # Returns the array of glob patterns that determine whether a given
    # path should be ignored by the model loader.
    #
    # @return [ Array<String> ] the array of ignore patterns
    def ignore_patterns
      @ignore_patterns ||= DEFAULT_IGNORE_PATTERNS.dup
    end

    # Sets the model paths to the given array of paths. These are the paths
    # where the application's model definitions are located.
    #
    # @param [ Array<String> ] paths The list of model paths
    def model_paths=(paths)
      @model_paths = paths
    end

    # Sets the ignore patterns to the given array of patterns. These are glob
    # patterns that determine whether a given path should be ignored by the
    # model loader or not.
    #
    # @param [ Array<String> ] patterns The list of glob patterns
    def ignore_patterns=(patterns)
      @ignore_patterns = patterns
    end

    # Returns true if the given file path matches any of the ignore patterns.
    #
    # @param [ String ] file_path The file path to consider
    #
    # @return [ true | false ] whether or not the given file path should be
    #   ignored.
    def ignored?(file_path)
      ignore_patterns.any? { |pattern| File.fnmatch?(pattern, file_path) }
    end
  end

end
