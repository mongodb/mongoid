# frozen_string_literal: true

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
    module Builders
      extend ActiveSupport::Concern

      private

      # Parses the arguments passed to the build and create methods. The first
      # argument is always the attributes (defaulting to {} if not given). The
      # last argument is always the options hash, if the last argument is a
      # hash. The first of any remaining arguments is the type.
      #
      # @param [ Array ] args The arguments passed to the method.
      #
      # @return [ Array ] An array containing the attributes, type, and options.
      def parse_args(args)
        attributes = args.shift || {}
        opts = args.last.is_a?(Hash) ? args.pop : {}
        type = args.shift

        [ attributes, type, opts ]
      end

      # Defines a builder method. This is defined as #build_name.
      #
      # @example
      #   Person.define_builder!(association)
      #
      # @param [ Mongoid::Association::Relatable ] association The association metadata.
      #
      # @return [ Class ] The class being set up.
      def self.define_builder!(association)
        association.inverse_class.tap do |klass|
          klass.re_define_method("build_#{association.name}") do |*args|
            attributes, type, _opts = parse_args(args)

            document = Factory.execute_build(type || association.relation_class, attributes, execute_callbacks: false)
            _building do
              child = send("#{association.name}=", document)
              child.run_pending_callbacks
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
      # @param [ Mongoid::Association::Relatable ] association The association metadata.
      #
      # @return [ Class ] The class being set up.
      def self.define_creator!(association)
        association.inverse_class.tap do |klass|
          klass.re_define_method("create_#{association.name}") do |*args|
            attributes, type, _opts = parse_args(args)

            document = Factory.execute_build(type || association.relation_class, attributes, execute_callbacks: false)
            doc = _assigning do
              send("#{association.name}=", document)
            end
            doc.run_pending_callbacks
            doc.save
            save if new_record? && association.stores_foreign_key?
            doc
          end
        end
      end
    end
  end
end
