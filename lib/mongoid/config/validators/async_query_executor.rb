# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Config
    module Validators

      # Validates the async query executor options in the Mongoid
      # configuration. Used during application bootstrapping.
      #
      # @api private
      module AsyncQueryExecutor
        extend self

        # Validate the Mongoid configuration options related to
        # the async query executor.
        #
        # @param [ Hash ] options The configuration options.
        #
        # @raises [ Mongoid::Errors::InvalidGlobalExecutorConcurrency ]
        #   Raised if the options are invalid.
        #
        # @api private
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
