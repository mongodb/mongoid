# frozen_string_literal: true

module Mongoid
  module Fields
    class Localized < Standard

      # Demongoize the object based on the current locale. Will look in the
      # hash for the current locale.
      #
      # @example Get the demongoized value.
      #   field.demongoize({ "en" => "testing" })
      #
      # @param [ Hash ] object The hash of translations.
      #
      # @return [ Object ] The value for the current locale.
      def demongoize(object)
        return if object.nil?
        case object
        when Hash
          type.demongoize(lookup(object))
        end
      end

      # Is the field localized or not?
      #
      # @example Is the field localized?
      #   field.localized?
      #
      # @return [ true | false ] If the field is localized.
      def localized?
        true
      end

      # Is the localized field enforcing values to be present?
      #
      # @example Is the localized field enforcing values to be present?
      #   field.localize_present?
      #
      # @return [ true | false ] If the field enforces present.
      def localize_present?
        options[:localize] == :present
      end

      # Convert the provided string into a hash for the locale.
      #
      # @example Serialize the value.
      #   field.mongoize("testing")
      #
      # @param [ String ] object The string to convert.
      #
      # @return [ Hash ] The locale with string translation.
      def mongoize(object)
        { ::I18n.locale.to_s => type.mongoize(object) }
      end

      private

      # Are fallbacks being used for this localized field.
      #
      # @api private
      #
      # @example Should fallbacks be used.
      #   field.fallbacks?
      #
      # @return [ true | false ] If fallbacks should be used.
      def fallbacks?
        return true if options[:fallbacks].nil?
        !!options[:fallbacks]
      end

      # Lookup the value from the provided object.
      #
      # @api private
      #
      # @example Lookup the value.
      #   field.lookup({ "en" => "test" })
      #
      # @param [ Hash ] object The localized object.
      #
      # @return [ Object ] The object for the locale.
      def lookup(object)
        locale = ::I18n.locale

        value = if object.key?(locale.to_s)
          object[locale.to_s]
        elsif object.key?(locale)
          object[locale]
        end
        return value unless value.nil?
        if fallbacks? && ::I18n.respond_to?(:fallbacks)
          fallback_key = ::I18n.fallbacks[locale].find do |loc|
            object.key?(loc.to_s) || object.key?(loc)
          end
          object[fallback_key.to_s] || object[fallback_key]
        end
      end
    end
  end
end
