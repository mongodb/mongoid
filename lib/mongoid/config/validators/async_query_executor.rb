# frozen_string_literal: true

module Mongoid
  module Config
    module Validators

      # Validator for async query executor configuration.
      #
      # @api private
      module AsyncQueryExecutor
        extend self


        def validate(options)
          if options.key?(:async_query_executor)
            if options[:async_query_executor].to_sym == :immediate && !options[:global_executor_concurrency].nil?
              raise Errors::InvalidGlobalExecutorConcurrency
            end
          end
        end
      end
    end
  end
end
