# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Nil #:nodoc:
      module Collectionization #:nodoc:
        def collectionize
          to_s.collectionize
        end
      end
    end
  end
end
