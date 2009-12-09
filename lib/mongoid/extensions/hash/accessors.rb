# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Hash #:nodoc:
      module Accessors #:nodoc:
        def insert(key, attrs)
          elements = self[key]
          if elements
            elements.update(attrs)
          else
            self[key] = key.singular? ? attrs : [attrs]
          end
        end
      end
    end
  end
end
