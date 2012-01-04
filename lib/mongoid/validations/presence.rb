# encoding: utf-8
module Mongoid #:nodoc:
  module Validations #:nodoc:
    
    # Validates that the specified attributes are not blank (as defined by
    # Object#blank?).
    #
    # @example Define the presence validator.
    #
    #   class Person
    #     include Mongoid::Document
    #     field :title
    #
    #     validates_presence_of :title
    #   end
    
    class PresenceValidator < ActiveModel::EachValidator
      def validate_each(document, attribute, value)
        if document.fields[attribute.to_s] && document.fields[attribute.to_s].localized? && value.kind_of?(Hash)
          value.keys.each do |language|
            document.errors.add(attribute, :blank, options) if value[language.to_s].blank?
          end
        else
          document.errors.add(attribute, :blank, options) if value.blank?
        end
      end
    end
  end
end
