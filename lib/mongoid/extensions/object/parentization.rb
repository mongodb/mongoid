module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Object #:nodoc:
      module Parentization #:nodoc:
        # Sets the parent object
        def parentize(object)
          self.parent = object
          add_observer(object)
        end
      end
    end
  end
end
