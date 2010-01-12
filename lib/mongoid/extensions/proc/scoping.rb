# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Proc #:nodoc:
      module Scoping #:nodoc:
        def scoped(*args)
          call(*args).scoped
        end
      end
    end
  end
end
