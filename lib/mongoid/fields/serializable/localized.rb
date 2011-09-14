# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Serializable #:nodoc:

      # Defines the behaviour for localized string fields.
      class Localized
        include Serializable

        def deserialize(object)
          object[locale]
        end

        def serialize(object)
          { locale => object.try(:to_s) }
        end

        private

        def locale
          (::I18n.locale || I18n.default_locale).to_s
        end
      end
    end
  end
end
