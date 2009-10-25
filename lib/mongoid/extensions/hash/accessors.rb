module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Hash #:nodoc:
      module Accessors #:nodoc:

        def insert(key, attrs)
          store(key, attrs) if singular?(key)
          if plural?(key)
            if has_key?(key)
              elements = fetch(key)
              elements.delete_if { |e| (e[:_id] == attrs[:_id]) }
              elements << attrs
            else
              store(key, [attrs])
            end
          end
        end

        def singular?(symbol)
          symbol.to_s.singularize == symbol.to_s
        end

        def plural?(symbol)
          symbol.to_s.pluralize == symbol.to_s
        end
      end
    end
  end
end
