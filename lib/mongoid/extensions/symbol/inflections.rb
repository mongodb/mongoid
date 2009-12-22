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

        ["gt", "lt", "gte", "lte", "ne", "in", "nin", "mod", "all", "size", "exists"].each do |oper|
          class_eval <<-OPERATORS
            def #{oper}
              ComplexCriterion.new(:key => self, :operator => "#{oper}")
            end
          OPERATORS
        end
      end
    end
  end
end
