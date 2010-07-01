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
      # Unfortunately, we have to tie Uniqueness validators to a class.
      def setup(klass)
        @klass = klass
      end
      
      def validate_each(document, attribute, value)
        criteria = @klass.where(attribute => value)
        
        Array.wrap(options[:scope]).each do |item|
          criteria = criteria.where(item => document.attributes[item])
        end
        
        unless document.new_record?
          criteria = criteria.where(:_id => {'$ne' => document._id})
        end
        
        if criteria.exists?
          document.errors.add(attribute, :taken, options.merge!(:value => value))
        end
      end

      protected
      def key_changed?(document)
        (document.primary_key || {}).each do |key|
          return true if document.send("#{key}_changed?")
        end; false
      end
    end
  end
end
