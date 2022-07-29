# frozen_string_literal: true

module Mongoid
  module Attributes

    # This module defines behavior for readonly attributes.
    module Readonly
      extend ActiveSupport::Concern

      included do
        class_attribute :readonly_attributes
        self.readonly_attributes = ::Set.new
      end

      # Are we able to write the attribute with the provided name?
      #
      # @example Can we write the attribute?
      #   model.attribute_writable?(:title)
      #
      # @param [ String | Symbol ] name The name of the field.
      #
      # @return [ true | false ] If the document is new, or if the field is not
      #   readonly.
      def attribute_writable?(name)
        new_record? || (!readonly_attributes.include?(name) && _loaded?(name))
      end

      private

      def as_writable_attribute!(name, value = :nil)
        normalized_name = database_field_name(name)
        if attribute_writable?(normalized_name)
          yield(normalized_name)
        else
          raise Errors::ReadonlyAttribute.new(name, value)
        end
      end

      def _loaded?(name)
        __selected_fields.nil? || projected_field?(name)
      end

      def projected_field?(name)
        projected = (__selected_fields || {}).keys.select { |f| __selected_fields[f] == 1 }
        projected.empty? || projected.include?(name)
      end

      module ClassMethods

        # Defines an attribute as readonly. This will ensure that the value for
        # the attribute is only set when the document is new or we are
        # creating. In other cases, the field write will be ignored with the
        # exception of #remove_attribute and #update_attribute, where an error
        # will get raised.
        #
        # @example Flag fields as readonly.
        #   class Band
        #     include Mongoid::Document
        #     field :name, type: String
        #     field :genre, type: String
        #     attr_readonly :name, :genre
        #   end
        #
        # @param [ Symbol... ] *names The names of the fields.
        def attr_readonly(*names)
          names.each do |name|
            readonly_attributes << database_field_name(name)
          end
        end
      end
    end
  end
end
