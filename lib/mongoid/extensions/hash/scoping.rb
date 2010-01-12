# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Hash #:nodoc:
      module Scoping #:nodoc:
        def scoped(*args)
          self
        end
      end
    end
  end
end
