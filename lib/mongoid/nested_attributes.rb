# encoding: utf-8
module Mongoid

  # Mongoid's implementation of Rails' nested attributes.
  module NestedAttributes
    extend ActiveSupport::Concern

    included do
      class_attribute :nested_attributes
      self.nested_attributes = {}
    end

    module ClassMethods

      REJECT_ALL_BLANK_PROC = ->(attributes){
        attributes.all? { |key, value| key == '_destroy' || value.blank? }
      }

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
      # @option *args [ Proc, Symbol ] :reject_if Block or symbol pointing
      #   to a class method to reject documents with.
      # @option *args [ Integer ] :limit The max number to create.
      # @option *args [ true, false ] :update_only Only update existing docs.
      def accepts_nested_attributes_for(*args)
        options = args.extract_options!
        options[:reject_if] = REJECT_ALL_BLANK_PROC if options[:reject_if] == :all_blank
        args.each do |name|
          meth = "#{name}_attributes="
          self.nested_attributes["#{name}_attributes"] = meth
          metadata = relations[name.to_s]
          unless metadata
            raise Errors::NestedAttributesMetadataNotFound.new(self, name)
          end
          autosave(metadata.merge!(autosave: true))
          re_define_method(meth) do |attrs|
            _assigning do
              metadata.nested_builder(attrs, options).build(self, mass_assignment_options)
            end
          end
        end
      end
    end
  end
end
