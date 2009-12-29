# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Hash #:nodoc:
      module Accessors #:nodoc:

        # Remove a set of attributes from a hash. If the attributes are
        # contained in an array it will remove it from the array, otherwise it
        # will delete the child attribute completely.
        def remove(key, attrs)
          elements = self[key]
          if elements
            key.singular? ? self[key] = nil : elements.delete(attrs)
          end
        end

        # Inserts new attributes into the hash. If the elements are present in
        # the hash it will update them, otherwise it will add the new
        # attributes into the hash as either a child hash or child array of
        # hashes.
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
