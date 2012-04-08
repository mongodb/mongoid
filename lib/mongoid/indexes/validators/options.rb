# encoding: utf-8
module Mongoid #:nodoc
  module Indexes #:nodoc
    module Validators

      # Validates the options passed to the index macro.
      module Options
        extend self

        VALID_OPTIONS = [ :background, :drop_dups, :name, :sparse, :unique ]
        VALID_TYPES = [ 1, -1, "2d" ]

        # Validate the index specification.
        #
        # @example Validate the index spec.
        #   Options.validate(Band, name: 1)
        #
        # @param [ Class ] klass The model class.
        # @param [ Hash ] spec The index specification.
        #
        # @raise [ Errors::InvalidIndex ] If validation failed.
        #
        # @since 3.0.0
        def validate(klass, spec)
          validate_spec(klass, spec)
          validate_options(klass, spec)
        end

        private

        # Validates the options of the index spec.
        #
        # @api private
        #
        # @example Validate the options.
        #   Options.validate_options(Band, name: 1)
        #
        # @param [ Class ] klass The model class.
        # @param [ Hash ] spec The index specification.
        #
        # @raise [ Errors::InvalidIndex ] If validation failed.
        #
        # @since 3.0.0
        def validate_options(klass, spec)
          (spec[:options] || {}).each_pair do |name, value|
            unless VALID_OPTIONS.include?(name)
              raise Errors::InvalidIndex.new(klass, spec)
            end
          end
        end

        # Validates the index spec.
        #
        # @api private
        #
        # @example Validate the spec.
        #   Options.validate_spec(Band, name: 1)
        #
        # @param [ Class ] klass The model class.
        # @param [ Hash ] spec The index specification.
        #
        # @raise [ Errors::InvalidIndex ] If validation failed.
        #
        # @since 3.0.0
        def validate_spec(klass, spec)
          raise Errors::InvalidIndex.new(klass, spec) if !spec.is_a?(::Hash)
          spec.each_pair do |name, value|
            next if name == :options
            unless VALID_TYPES.include?(value)
              raise Errors::InvalidIndex.new(klass, spec)
            end
          end
        end
      end
    end
  end
end
