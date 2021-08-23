# frozen_string_literal: true

module Mongoid
  module Config
    module Validators

      # Validator for configuration options.
      module Option
        extend self

        # Validate a configuration option.
        #
        # @example Validate a configuration option.
        #
        # @param [ String ] option The name of the option.
        def validate(option)
          unless Config.settings.keys.include?(option.to_sym)
            raise Errors::InvalidConfigOption.new(option)
          end
        end
      end
    end
  end
end
