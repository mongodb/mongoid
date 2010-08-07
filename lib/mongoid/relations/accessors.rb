# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Accessors #:nodoc:
      extend ActiveSupport::Concern

      private

      # Set the supplied relation to an instance variable on the class with the
      # provided name. Used as a helper just for code cleanliness.
      #
      # Options:
      #
      # name: The name of the association.
      # relation: The relation to set.
      def set(name, relation)
        instance_variable_set("@#{name}", relation)
      end

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
        #
        # Returns:
        #
        # self
        def getter(name)
          tap do
            define_method(name) do
              variable = "@#{name}"
              if instance_variable_defined?(variable)
                instance_variable_get(variable)
              end
            end
          end
        end

        # Defines the setter for the relation. This does a few things based on
        # some conditions. If there is an existing association, a target
        # substitution will take place, otherwise a new relation will be
        # created with the supplied target.
        #
        # Example:
        #
        # <tt>Person.setter("addresses", metadata, relation)</tt>
        #
        # Options:
        #
        # name: The name of the relation.
        # metadata: The metadata for the relation.
        # relation: the class for the relation.
        #
        # Returns:
        #
        # self
        def setter(name, metadata, relation)
          tap do
            define_method("#{name}=") do |target|
              existing = send(name)
              if existing
                set(name, existing.substitute(target))
              else
                set(name, relation.new(self, target, metadata))
              end
            end
          end
        end
      end
    end
  end
end
