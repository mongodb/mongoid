# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module TrueClass #:nodoc:
      module Equality #:nodoc:
        def is_a?(other)
          return true if other.name == "Boolean"
          super(other)
        end
      end
    end
  end
end
