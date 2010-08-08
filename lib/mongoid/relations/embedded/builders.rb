# encoding: utf-8
require "mongoid/relations/embedded/builder"
require "mongoid/relations/embedded/builders/in"
require "mongoid/relations/embedded/builders/many"
require "mongoid/relations/embedded/builders/one"

module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded #:nodoc:
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
end
