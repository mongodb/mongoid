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
        if document.embedded?
          return if document._parent.nil?
          criteria = document._parent.send(document.association_name)
          # If the parent document embeds_one, no need to validate uniqueness
          return if criteria.is_a?(Mongoid::Document)
          criteria = criteria.where(attribute => unique_search_value(value), :_id => {'$ne' => document._id})
        else
          criteria = @klass.where(attribute => unique_search_value(value))
          unless document.new_record?
            criteria = criteria.where(:_id => {'$ne' => document._id})
          end
        end

        Array.wrap(options[:scope]).each do |item|
          criteria = criteria.where(item => document.attributes[item])
        end
        if criteria.exists?
          document.errors.add(
            attribute,
            :taken,
            options.except(:case_sensistive, :scope).merge(:value => value)
          )
        end
      end

      protected
      def key_changed?(document)
        (document.primary_key || {}).each do |key|
          return true if document.send("#{key}_changed?")
        end; false
      end

      # ensure :case_sensitive is true by default
      def unique_search_value(value)
        if options[:case_sensitive] == false
          value ? Regexp.new("^#{Regexp.escape(value.to_s)}$", Regexp::IGNORECASE) : nil
        else
          value
        end
      end
    end
  end
end
