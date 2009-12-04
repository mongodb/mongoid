# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Array #:nodoc:
      module Parentization #:nodoc:
        # Adds the parent document to each element in the array.
        def parentize(parent, association_name)
          each { |obj| obj.parentize(parent, association_name) }
        end
      end
    end
  end
end
