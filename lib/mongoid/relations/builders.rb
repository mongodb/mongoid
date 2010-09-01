# encoding: utf-8
require "mongoid/relations/builder"
require "mongoid/relations/nested_builder"
require "mongoid/relations/builders/embedded/in"
require "mongoid/relations/builders/embedded/many"
require "mongoid/relations/builders/embedded/one"
require "mongoid/relations/builders/nested_attributes/one"
require "mongoid/relations/builders/nested_attributes/many"
require "mongoid/relations/builders/referenced/in"
require "mongoid/relations/builders/referenced/in_from_array"
require "mongoid/relations/builders/referenced/many"
require "mongoid/relations/builders/referenced/many_as_array"
require "mongoid/relations/builders/referenced/many_to_many"
require "mongoid/relations/builders/referenced/one"

module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Builders #:nodoc:
      extend ActiveSupport::Concern

      module ClassMethods #:nodoc:

        # Defines a builder method for an embeds_one relation. This is
        # defined as <tt>build_#{relation_name}</tt>.
        #
        # Example:
        #
        # <tt>klass.builder("name")</tt>
        #
        # Options:
        #
        # name: The name of the relation.
        #
        # Returns:
        #
        # The klass.
        def builder(name)
          tap do
            define_method("build_#{name}") do |object|
              send("#{name}=", object)
            end
          end
        end

        # Defines a creator method for an embeds_one relation. This is
        # defined as <tt>create_#{relation_name}</tt>. After the object is
        # built, it will immediately save.
        #
        # Example:
        #
        # <tt>klass.creator("name")</tt>
        #
        # Options:
        #
        # name: The name of the relation.
        #
        # Returns:
        #
        # The klass.
        def creator(name)
          tap do
            define_method("create_#{name}") do |object|
              send("#{name}=", object).tap(&:save)
            end
          end
        end
      end
    end
  end
end
