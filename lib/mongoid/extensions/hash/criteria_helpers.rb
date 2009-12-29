# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Hash #:nodoc:
      module CriteriaHelpers #:nodoc:
        def expand_complex_criteria
          hsh = {}
          self.each_pair do |k,v|
            if k.class == Mongoid::ComplexCriterion
              hsh[k.key] = {"$#{k.operator}" => v}
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