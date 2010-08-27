# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Hash #:nodoc:
      module Assimilation #:nodoc:
        # Introduces a child object into the +Document+ object graph. This will
        # set up the relationships between the parent and child and update the
        # attributes of the parent +Document+.
        #
        # Options:
        #
        # parent: The +Document+ to assimilate into.
        # options: The association +Options+ for the child.
        #
        # Example:
        #
        # <tt>{:first_name => "Hank", :last_name => "Moody"}.assimilate(name, options)</tt>
        #
        # Returns: The child +Document+.
        def assimilate(parent, options, type = nil)
          klass = self.klass || (type ? type : options.klass)
          child = klass.instantiate("_id" => self["_id"])
          self.merge("_type" => klass.name) if klass.hereditary?
          init(parent, child, options)
        end

        protected

        def init(parent, child, options)
          child.parentize(parent, options.name)
          child.write_attributes(self)
          child.identify
          child.reset_modifications
          child.notify
          child
        end
      end
    end
  end
end
