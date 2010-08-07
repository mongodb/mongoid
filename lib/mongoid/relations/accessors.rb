# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Accessors #:nodoc:
      extend ActiveSupport::Concern

      module ClassMethods #:nodoc:

        # Defines the getter for the relation. Nothing too special here: just
        # return the instance variable for the relation if it exists.
        #
        # Example:
        #
        # <tt>Person.getter("addresses")</tt>
        #
        # Options:
        #
        # name: The name of the relation.
        def getter(name)
          define_method(name) do
            variable = "@#{name}"
            if instance_variable_defined?(variable)
              instance_variable_get(variable)
            end
          end
        end

        def setter(name, metadata, relation)
          define_method("#{name}=") do |document|
            # If relation exists, reset the target of the relation.
            # If relation does not exist, create a new one and set the target.
            # If the document is nil:
            #   When a one-to-one set the relation to nil.
            #   When a one-to-many clear the target.
            instance_variable_set("@#{name}", document)
          end
        end
      end
    end
  end
end
