# encoding: utf-8
require "mongoid/relations/builder"
require "mongoid/relations/nested_builder"
require "mongoid/relations/builders/embedded/in"
require "mongoid/relations/builders/embedded/many"
require "mongoid/relations/builders/embedded/one"
require "mongoid/relations/builders/nested_attributes/one"
require "mongoid/relations/builders/nested_attributes/many"
require "mongoid/relations/builders/referenced/in"
require "mongoid/relations/builders/referenced/many"
require "mongoid/relations/builders/referenced/many_to_many"
require "mongoid/relations/builders/referenced/one"

module Mongoid # :nodoc:
  module Relations #:nodoc:

    # This module is responsible for defining the build and create methods used
    # in one to one relations.
    #
    # @example Methods that get created.
    #
    #   class Person
    #     include Mongoid::Document
    #     embeds_one :name
    #   end
    #
    #   # The following methods get created:
    #   person.build_name({ :first_name => "Durran" })
    #   person.create_name({ :first_name => "Durran" })
    #
    # @since 2.0.0.rc.1
    module Builders
      extend ActiveSupport::Concern

      private

      # Parse out the attributes and the options from the args passed to a
      # build_ or create_ methods.
      #
      # @example Parse the args.
      #   doc.parse_args(:name => "Joe")
      #
      # @param [ Array ] args The arguments.
      #
      # @return [ Array<Hash> ] The attributes and options.
      #
      # @since 2.3.4
      def parse_args(*args)
        [ args.first || {}, args.size > 1 ? args[1] : {} ]
      end

      module ClassMethods #:nodoc:

        # Defines a builder method for an embeds_one relation. This is
        # defined as #build_name.
        #
        # @example
        #   Person.builder("name")
        #
        # @param [ String, Symbol ] name The name of the relation.
        #
        # @return [ Class ] The class being set up.
        #
        # @since 2.0.0.rc.1
        def builder(name, metadata)
          re_define_method("build_#{name}") do |*args|
            attributes, options = parse_args(*args)
            document = Factory.build(metadata.klass, attributes, options)
            _building do
              child = send("#{name}=", document)
              child.run_callbacks(:build)
              child
            end
          end
          self
        end

        # Defines a creator method for an embeds_one relation. This is
        # defined as #create_name. After the object is built it will
        # immediately save.
        #
        # @example
        #   Person.creator("name")
        #
        # @param [ String, Symbol ] name The name of the relation.
        #
        # @return [ Class ] The class being set up.
        #
        # @since 2.0.0.rc.1
        def creator(name, metadata)
          re_define_method("create_#{name}") do |*args|
            attributes, options = parse_args(*args)
            document = Factory.build(metadata.klass, attributes, options)
            doc = send("#{name}=", document)
            doc.save
            save if new_record? && metadata.stores_foreign_key?
            doc
          end
          self
        end
      end
    end
  end
end
