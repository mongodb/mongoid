# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Accessors #:nodoc:
      extend ActiveSupport::Concern

      private

      # Determines if the relation exists or not.
      #
      # Options:
      #
      # name: The name of the relation to check.
      #
      # Returns:
      #
      # true if set and not nil, false if not.
      def relation_exists?(name)
        ivar(name)
      end

      # Set the supplied relation to an instance variable on the class with the
      # provided name. Used as a helper just for code cleanliness.
      #
      # Options:
      #
      # name: The name of the relation.
      # relation: The relation to set.
      #
      # Returns:
      #
      # The relation.
      def set(name, relation)
        instance_variable_set("@#{name}", relation)
      end

      # Builds the related document and creates the relation unless the
      # document is nil, then sets the relation on this document.
      #
      # Options:
      #
      # name: The name of the relation.
      # object: The document or attributes to build.
      # metadata: The relation's metadata.
      #
      # Returns:
      #
      # The relation
      def build(name, object, metadata, building = nil)
        target = metadata.builder(object).build
        relation = metadata.relation.new(self, target, metadata) if target
        set(name, relation).tap do |relation|
          relation.bind(building) if relation
        end
      end

      def building?(args)
        args.length > 1 ? args.last : false
      end

      module ClassMethods #:nodoc:

        # Defines the getter for the relation. Nothing too special here: just
        # return the instance variable for the relation if it exists.
        #
        # Example:
        #
        # <tt>Person.getter("addresses", metadata)</tt>
        #
        # Options:
        #
        # name: The name of the relation.
        # metadata: The metadata for the relation.
        #
        # Returns:
        #
        # self
        def getter(name, metadata)
          tap do
            define_method(name) do
              variable = "@#{name}"
              if instance_variable_defined?(variable)
                instance_variable_get(variable)
              else
                build(name, @attributes.delete(metadata.key), metadata)
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
        # <tt>Person.setter("addresses", metadata)</tt>
        #
        # Options:
        #
        # name: The name of the relation.
        # metadata: The metadata for the relation.
        #
        # Returns:
        #
        # self
        def setter(name, metadata)
          tap do
            define_method("#{name}=") do |*args|
              object, building = args.first, building?(args)
              variable = "@#{name}"
              if relation_exists?(name)
                set(name, send(name).substitute(object, building))
              else
                build(name, object, metadata, building)
              end
            end
          end
        end
      end
    end
  end
end
