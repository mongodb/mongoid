# encoding: utf-8
module Mongoid
  module Indexes
    module Validators

      # Validates the options passed to the index macro.
      module Options
        extend self

        VALID_OPTIONS = [ :background, :drop_dups, :name, :sparse, :unique, :max, :min, :bits, :bucket_size ]
        VALID_TYPES = [ 1, -1, "2d", "geoHaystack" ]

        # Validate the index specification.
        #
        # @example Validate the index spec.
        #   Options.validate(Band, name: 1)
        #
        # @param [ Class ] klass The model class.
        # @param [ Hash ] spec The index specification.
        # @param [ Hash ] options The index options.
        #
        # @raise [ Errors::InvalidIndex ] If validation failed.
        #
        # @since 3.0.0
        def validate(klass, spec, options)
          validate_spec(klass, spec, options)
          validate_options(klass, spec, options)
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
        # @param [ Hash ] options The index options.
        #
        # @raise [ Errors::InvalidIndex ] If validation failed.
        #
        # @since 3.0.0
        def validate_options(klass, spec, options)
          options.each_pair do |name, value|
            unless VALID_OPTIONS.include?(name)
              raise Errors::InvalidIndex.new(klass, spec, options)
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
        # @param [ Hash ] options The index options.
        #
        # @raise [ Errors::InvalidIndex ] If validation failed.
        #
        # @since 3.0.0
        def validate_spec(klass, spec, options)
          raise Errors::InvalidIndex.new(klass, spec, options) if !spec.is_a?(::Hash)
          spec.each_pair do |name, value|
            next if name == :options
            unless VALID_TYPES.include?(value)
              raise Errors::InvalidIndex.new(klass, spec, options)
            end
          end
        end
      end
    end
  end
end
