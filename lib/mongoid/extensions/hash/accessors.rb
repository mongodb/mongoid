module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Hash #:nodoc:
      module Accessors #:nodoc:
        def insert(key, attrs)
          store(key, attrs) if key.singular?
          if key.plural?
            if has_key?(key)
              elements = fetch(key)
              elements.delete_if { |e| (e[:_id] == attrs[:_id]) }
              elements << attrs
            else
              store(key, [attrs])
            end
          end
        end
      end
    end
  end
end
