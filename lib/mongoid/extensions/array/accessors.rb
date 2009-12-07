# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Array #:nodoc:
      module Accessors #:nodoc:
        # If the attributes already exists in the array then they will be
        # updated, otherwise they will be appended.
        def update(attributes)
          delete_if { |e| attributes[:_id] && (e[:_id] == attributes[:_id]) }
          self.<< attributes
        end
      end
    end
  end
end
