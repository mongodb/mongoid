module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Date #:nodoc:
      module Conversions #:nodoc:
        def set(value)
          value.to_time unless value.blank?
        end
        def get(value)
          value ? value.getlocal.to_date : value
        end
      end
    end
  end
end
