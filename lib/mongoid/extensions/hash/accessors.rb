module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Hash #:nodoc:
      module Accessors #:nodoc:
        def insert(key, attrs)
          self[key] = attrs if key.singular?
          if key.plural?
            if elements = self[key]
              elements.delete_if { |e| (e[:_id] == attrs[:_id]) } << attrs
            else
              self[key] = [attrs]
            end
          end
        end
      end
    end
  end
end
