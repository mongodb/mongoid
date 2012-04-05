# encoding: utf-8
module Mongoid
  module Config
    module Validators

      # Validator for configuration options.
      module Option
        extend self

        # Validate a configuration option.
        #
        # @example Validate a configuraiton option.
        #
        # @param [ String ] option The name of the option.
        #
        # @since 3.0.0
        def validate(option)
          unless Config.settings.keys.include?(option.to_sym)
            raise Errors::InvalidConfigOption.new(option)
          end
        end
      end
    end
  end
end
