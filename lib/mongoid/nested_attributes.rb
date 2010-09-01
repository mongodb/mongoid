# encoding: utf-8
module Mongoid #:nodoc:
  module NestedAttributes
    extend ActiveSupport::Concern

    module ClassMethods

      # Used when needing to update related models from a parent relation. Can
      # be used on embedded or referenced relations.
      #
      # Example:
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
      # This will define a setter for the relation in the form of
      # <tt>#{relation_name}_attributes=</tt>. So the above example would get
      # the following methods added:
      #
      #   addresses_attributes=
      #   game_attributes=
      #   posts_attributes=
      #
      # Options:
      #
      # args: A list of relation names, followed by a hash of options. The
      #       available options are:
      #
      #       :allow_destroy,
      #       :reject_if,
      #       :limit,
      #       :update_only.
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
