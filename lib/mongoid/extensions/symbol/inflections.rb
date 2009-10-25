module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Symbol #:nodoc:
      module Inflections #:nodoc:
        def singular?
          to_s.singularize == to_s
        end
        def plural?
          to_s.pluralize == to_s
        end
      end
    end
  end
end
