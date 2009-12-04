# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Array #:nodoc:
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
        # <tt>[{:street => "Queen St."}, {:street => "King St."}].assimilate(person, options)</tt>
        #
        # Returns: The child +Document+.
        def assimilate(parent, options)
          each { |child| child.assimilate(parent, options) }
        end
      end
    end
  end
end
