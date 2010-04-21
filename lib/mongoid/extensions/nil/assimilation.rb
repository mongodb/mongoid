# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Nil #:nodoc:
      module Assimilation #:nodoc:
        # Will remove the child object from the parent.
        def assimilate(parent, options, type = nil)
          parent.remove_attribute(options.name); self
        end

        def collectionize
          to_s.collectionize
        end
      end
    end
  end
end
