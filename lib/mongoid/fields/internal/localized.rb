# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Internal #:nodoc:

      # Defines the behaviour for localized string fields.
      class Localized
        include Serializable

        # Deserialize the object based on the current locale. Will look in the
        # hash for the current locale.
        #
        # @example Get the deserialized value.
        #   field.deserialize({ "en" => "testing" })
        #
        # @param [ Hash ] object The hash of translations.
        #
        # @return [ String ] The value for the current locale.
        #
        # @since 2.3.0
        def deserialize(object)
          return nil if object.nil?
          locale = ::I18n.locale
          if ::I18n.respond_to?(:fallbacks)
            object[::I18n.fallbacks[locale].map(&:to_s).find{ |loc| object[loc] }]
          else
            object[locale.to_s]
          end
        end

        # Special case to serialize the object.
        #
        # @example Convert to a selection.
        #   field.selection(object)
        #
        # @param [ Object ] The object to convert.
        #
        # @return [ Object ] The converted object.
        #
        # @since 2.4.0
        def selection(object)
          return object if object.is_a?(::Hash)
          serialize(object)
        end

        # Convert the provided string into a hash for the locale.
        #
        # @example Serialize the value.
        #   field.serialize("testing")
        #
        # @param [ String ] object The string to convert.
        #
        # @return [ Hash ] The locale with string translation.
        #
        # @since 2.3.0
        def serialize(object)
          { ::I18n.locale.to_s => object.try(:to_s) }
        end
      end
    end
  end
end
