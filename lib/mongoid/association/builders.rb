# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Association

    # This module is responsible for defining the build and create methods used
    # in one to one associations.
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

      # Defines a builder method. This is defined as #build_name.
      #
      # @example
      #   Person.define_builder!(association)
      #
      # @param [ Association ] association The association metadata for the association.
      #
      # @return [ Class ] The class being set up.
      #
      # @since 2.0.0.rc.1
      def self.define_builder!(association)
        association.inverse_class.tap do |klass|
          klass.re_define_method("build_#{association.name}") do |*args|
            attributes, _options = parse_args(*args)
            document = Factory.build(association.relation_class, attributes)
            _building do
              child = send("#{association.name}=", document)
              child.run_callbacks(:build)
              child
            end
          end
        end
      end

      # Defines a creator method. This is defined as #create_name.
      # After the object is built it will immediately save.
      #
      # @example
      #   Person.define_creator!(association)
      #
      # @param [ Association ] association The association metadata for the association.
      #
      # @return [ Class ] The class being set up.
      #
      # @since 2.0.0.rc.1
      def self.define_creator!(association)
        association.inverse_class.tap do |klass|
          klass.re_define_method("create_#{association.name}") do |*args|
            attributes, _options = parse_args(*args)
            document = Factory.build(association.relation_class, attributes)
            doc = _assigning do
              send("#{association.name}=", document)
            end
            doc.save
            save if new_record? && association.stores_foreign_key?
            doc
          end
        end
      end
    end
  end
end
