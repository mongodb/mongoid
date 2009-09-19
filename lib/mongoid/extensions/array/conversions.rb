module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Object #:nodoc:
      # This module converts objects into mongoid related objects.
      module Conversions #:nodoc:
        # Converts this object to a hash of attributes
        def mongoidize
          self.attributes
        end
      end
    end
  end
end