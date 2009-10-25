module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Object #:nodoc:
      module Parentization #:nodoc:
        # Sets the parent object
        def parentize(object, association_name)
          self.parent = object
          self.association_name = association_name
          add_observer(object)
        end
      end
    end
  end
end
