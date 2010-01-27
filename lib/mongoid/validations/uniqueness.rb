# encoding: utf-8
module Mongoid #:nodoc:
  module Validations #:nodoc:
    # Validates whether or not a field is unique against the documents in the
    # database.
    #
    # Example:
    #
    #   class Person
    #     include Mongoid::Document
    #     field :title
    #
    #     validates_uniqueness_of :title
    #   end
    class UniquenessValidator < ActiveModel::EachValidator
      def validate_each(document, attribute, value)
        return if document.class.where(attribute => value).empty?
        document.errors.add(
          attribute,
          :taken,
          :default => options[:message],
          :value => value
        )
      end
    end
  end
end
