# encoding: utf-8
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

        [ "asc", "ascending", "desc", "descending", "gt", "lt", "gte",
          "lte", "ne", "near", "in", "nin", "mod", "all", "size", "exists",
          "within", ["matches","elemMatch"] ].each do |oper|
          m, oper = oper
          oper = m unless oper
          class_eval <<-OPERATORS
            def #{m}
              Criterion::Complex.new(:key => self, :operator => "#{oper}")
            end
          OPERATORS
        end
      end
    end
  end
end
