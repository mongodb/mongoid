# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Hash #:nodoc:
      module CriteriaHelpers #:nodoc:
        def expand_complex_criteria
          hsh = {}
          each_pair do |k,v|
            case k
            when Mongoid::Criterion::Complex
              hsh[k.key] ||= {}
              hsh[k.key].merge!({"$#{k.operator}" => v})
            else
              hsh[k] = v
            end
          end
          hsh
        end
      end
    end
  end
end
