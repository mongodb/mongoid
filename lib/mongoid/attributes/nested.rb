# encoding: utf-8
module Mongoid
  module Attributes

    # Defines behaviour around that lovel Rails feature nested attributes.
    #
    # @since 1.0.0
    module Nested
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
            raise Errors::NestedAttributesMetadataNotFound.new(self, name) unless metadata
            autosave_nested_attributes(metadata)
            re_define_method(meth) do |attrs|
              _assigning do
                if metadata.polymorphic? and metadata.inverse_type
                  options = options.merge!(:class_name => self.send(metadata.inverse_type))
                end
                metadata.nested_builder(attrs, options).build(self)
              end
            end
          end
        end

        private

        # Add the autosave information for the nested relation.
        #
        # @api private
        #
        # @example Add the autosave if appropriate.
        #   Person.autosave_nested_attributes(metadata)
        #
        # @param [ Metadata ] metadata The existing relation metadata.
        #
        # @since 3.1.4
        def autosave_nested_attributes(metadata)
          unless metadata.autosave == false
            autosave(metadata.merge!(autosave: true))
          end
        end
      end
    end
  end
end
