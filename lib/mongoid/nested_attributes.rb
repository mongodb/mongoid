# encoding: utf-8
module Mongoid #:nodoc:
  module NestedAttributes
    extend ActiveSupport::Concern

    module ClassMethods

      # Used when needing to update related models from a parent relation. Can
      # be used on embedded or referenced relations.
      #
      # @example Defining nested attributes.
      #
      #   class Person
      #     include Mongoid::Document
      #
      #     embeds_many :addresses
      #     embeds_one :game
      #     references_many :posts
      #
      #     accepts_nested_attributes_for :addresses, :game, :posts
      #   end
      #
      # @param [ Array<Symbol>, Hash ] *args A list of relation names, followed
      #   by a hash of options.
      #
      # @option *args [ true, false ] :allow_destroy Can deletion occur?
      # @option *args [ Proc ] :reject_if Block to reject documents with.
      # @option *args [ Integer ] :limit The max number to create.
      # @option *args [ true, false ] :update_only Only update existing docs.
      def accepts_nested_attributes_for(*args)
        options = args.extract_options!
        args.each do |name|
          define_method("#{name}_attributes=") do |attrs|
            relation = relations[name.to_s]
            relation.nested_builder(attrs, options).build(self)
          end
        end
      end
    end
  end
end
