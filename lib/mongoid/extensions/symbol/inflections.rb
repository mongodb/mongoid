module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Symbol #:nodoc:
      module Inflections #:nodoc:

        REVERSALS = {
          :asc => :desc,
          :ascending => :descending,
          :desc => :asc,
          :descending => :ascending
        }

        def invert
          REVERSALS[self]
        end

        def singular?
          to_s.singular?
        end

        def plural?
          to_s.plural?
        end

      end
    end
  end
end
