module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module String #:nodoc:
      module Inflections #:nodoc:
        def singular?
          singularize == self
        end
        def plural?
          pluralize == self
        end
      end
    end
  end
end
