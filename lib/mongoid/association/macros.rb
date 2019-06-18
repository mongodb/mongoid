# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Association

    # This module contains the core macros for defining associations between
    # documents. They can be either embedded or referenced.
    module Macros
      extend ActiveSupport::Concern

      included do
        class_attribute :embedded, instance_reader: false
        class_attribute :embedded_relations
        class_attribute :relations
        self.embedded = false
        self.embedded_relations = BSON::Document.new
        self.relations = BSON::Document.new
      end

      # This is convenience for libraries still on the old API.
      #
      # @example Get the associations.
      #   person.associations
      #
      # @return [ Hash ] The associations.
      #
      # @since 2.3.1
      def associations
        self.relations
      end

      module ClassMethods

        # Adds the association back to the parent document. This macro is
        # necessary to set the references from the child back to the parent
        # document. If a child does not define this association calling
        # persistence methods on the child object will cause a save to fail.
        #
        # @example Define the association.
        #
        #   class Person
        #     include Mongoid::Document
        #     embeds_many :addresses
        #   end
        #
        #   class Address
        #     include Mongoid::Document
        #     embedded_in :person
        #   end
        #
        # @param [ Symbol ] name The name of the association.
        # @param [ Hash ] options The association options.
        # @param [ Proc ] block Optional block for defining extensions.
        def embedded_in(name, options = {}, &block)
          define_association!(__method__, name, options, &block)
        end

        # Adds the association from a parent document to its children. The name
        # of the association needs to be a pluralized form of the child class
        # name.
        #
        # @example Define the association.
        #
        #   class Person
        #     include Mongoid::Document
        #     embeds_many :addresses
        #   end
        #
        #   class Address
        #     include Mongoid::Document
        #     embedded_in :person
        #   end
        #
        # @param [ Symbol ] name The name of the association.
        # @param [ Hash ] options The association options.
        # @param [ Proc ] block Optional block for defining extensions.
        def embeds_many(name, options = {}, &block)
          define_association!(__method__, name, options, &block)
        end

        # Adds the association from a parent document to its child. The name
        # of the association needs to be a singular form of the child class
        # name.
        #
        # @example Define the association.
        #
        #   class Person
        #     include Mongoid::Document
        #     embeds_one :name
        #   end
        #
        #   class Name
        #     include Mongoid::Document
        #     embedded_in :person
        #   end
        #
        # @param [ Symbol ] name The name of the association.
        # @param [ Hash ] options The association options.
        # @param [ Proc ] block Optional block for defining extensions.
        def embeds_one(name, options = {}, &block)
          define_association!(__method__, name, options, &block)
        end

        # Adds a referenced association from the child Document to a Document
        # in another database or collection.
        #
        # @example Define the association.
        #
        #   class Game
        #     include Mongoid::Document
        #     belongs_to :person
        #   end
        #
        #   class Person
        #     include Mongoid::Document
        #     has_one :game
        #   end
        #
        # @param [ Symbol ] name The name of the association.
        # @param [ Hash ] options The association options.
        # @param [ Proc ] block Optional block for defining extensions.
        def belongs_to(name, options = {}, &block)
          define_association!(__method__, name, options, &block)
        end

        # Adds a referenced association from a parent Document to many
        # Documents in another database or collection.
        #
        # @example Define the association.
        #
        #   class Person
        #     include Mongoid::Document
        #     has_many :posts
        #   end
        #
        #   class Game
        #     include Mongoid::Document
        #     belongs_to :person
        #   end
        #
        # @param [ Symbol ] name The name of the association.
        # @param [ Hash ] options The association options.
        # @param [ Proc ] block Optional block for defining extensions.
        def has_many(name, options = {}, &block)
          define_association!(__method__, name, options, &block)
        end

        # Adds a referenced many-to-many association between many of this
        # Document and many of another Document.
        #
        # @example Define the association.
        #
        #   class Person
        #     include Mongoid::Document
        #     has_and_belongs_to_many :preferences
        #   end
        #
        #   class Preference
        #     include Mongoid::Document
        #     has_and_belongs_to_many :people
        #   end
        #
        # @param [ Symbol ] name The name of the association.
        # @param [ Hash ] options The association options.
        # @param [ Proc ] block Optional block for defining extensions.
        #
        # @since 2.0.0.rc.1
        def has_and_belongs_to_many(name, options = {}, &block)
          define_association!(__method__, name, options, &block)
        end

        # Adds a referenced association from the child Document to a Document
        # in another database or collection.
        #
        # @example Define the association.
        #
        #   class Game
        #     include Mongoid::Document
        #     belongs_to :person
        #   end
        #
        #   class Person
        #     include Mongoid::Document
        #     has_one :game
        #   end
        #
        # @param [ Symbol ] name The name of the association.
        # @param [ Hash ] options The association options.
        # @param [ Proc ] block Optional block for defining extensions.
        def has_one(name, options = {}, &block)
          define_association!(__method__, name, options, &block)
        end

        private

        def define_association!(macro_name, name, options = {}, &block)
          Association::MACRO_MAPPING[macro_name].new(self, name, options, &block).tap do |assoc|
            assoc.setup!
            self.relations = self.relations.merge(name => assoc)
          end
        end
      end
    end
  end
end
