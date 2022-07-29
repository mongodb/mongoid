# frozen_string_literal: true

module Mongoid
  module Attributes

    # Defines behavior around that lovel Rails feature nested attributes.
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

        # Used when needing to update related models from a parent association. Can
        # be used on embedded or referenced associations.
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
        # @param [ Symbol..., Hash ] *args A list of association names, followed
        #   by an optional hash of options.
        #
        # @option *args [ true | false ] :allow_destroy Can deletion occur?
        # @option *args [ Proc | Symbol ] :reject_if Block or symbol pointing
        #   to a class method to reject documents with.
        # @option *args [ Integer ] :limit The max number to create.
        # @option *args [ true | false ] :update_only Only update existing docs.
        # @option *args [ true | false ] :autosave Whether autosave should be enabled on the
        #   association. Note that since the default is true, setting autosave to nil will still
        #   enable it.
        def accepts_nested_attributes_for(*args)
          options = args.extract_options!.dup
          options[:autosave] = true if options[:autosave].nil?

          options[:reject_if] = REJECT_ALL_BLANK_PROC if options[:reject_if] == :all_blank
          args.each do |name|
            meth = "#{name}_attributes="
            self.nested_attributes["#{name}_attributes"] = meth
            association = relations[name.to_s]
            raise Errors::NestedAttributesMetadataNotFound.new(self, name) unless association
            autosave_nested_attributes(association) if options[:autosave]

            re_define_method(meth) do |attrs|
              _assigning do
                if association.polymorphic? and association.inverse_type
                  options = options.merge!(:class_name => self.send(association.inverse_type))
                end
                association.nested_builder(attrs, options).build(self)
              end
            end
          end
        end

        private

        # Add the autosave information for the nested association.
        #
        # @api private
        #
        # @example Add the autosave if appropriate.
        #   Person.autosave_nested_attributes(metadata)
        #
        # @param [ Association ] association The existing association metadata.
        def autosave_nested_attributes(association)
          # In order for the autosave functionality to work properly, the association needs to be
          # marked as autosave despite the fact that the option isn't present. Because the method
          # Association#autosave? is implemented by checking the autosave option, this is the most
          # straightforward way to mark it.
          if association.autosave? || (association.options[:autosave].nil? && !association.embedded?)
            association.options[:autosave] = true
            Association::Referenced::AutoSave.define_autosave!(association)
          end
        end
      end
    end
  end
end
