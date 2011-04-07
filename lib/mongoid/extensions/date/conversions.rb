# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Date #:nodoc:
      module Conversions #:nodoc:
        def get(value)
          return nil if value.blank?
          if Mongoid::Config.use_utc?
            value.to_date
          else
            ::Date.new(value.year, value.month, value.day)
          end
        end

        # +Date+ is not inherently represented as a data type in MongoDB
        def needs_type_casting?
          true
        end

        protected

        def convert_to_time(value)
          value = ::Date.parse(value) if value.is_a?(::String)
          value = ::Date.civil(*value) if value.is_a?(::Array)
          ::Time.utc(value.year, value.month, value.day)
        end
      end
    end
  end
end
