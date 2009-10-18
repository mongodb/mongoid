module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Array #:nodoc:
      # This module converts arrays into mongoid related objects.
      module Conversions #:nodoc:
        # Converts this array into an array of hashes.
        def mongoidize
          collect { |obj| obj.attributes }
        end
      end
    end
  end
end
