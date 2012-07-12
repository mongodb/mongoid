# encoding: utf-8
module Mongoid #:nodoc:
  module Validations #:nodoc:

    # Validates whether or not a field is unique against the documents in the
    # database.
    #
    # @example Define the uniqueness validator.
    #
    #   class Person
    #     include Mongoid::Document
    #     field :title
    #
    #     validates_uniqueness_of :title
    #   end
    class UniquenessValidator < ActiveModel::EachValidator
      attr_reader :klass

      # Unfortunately, we have to tie Uniqueness validators to a class.
      #
      # @example Setup the validator.
      #   UniquenessValidator.new.setup(Person)
      #
      # @param [ Class ] klass The class getting validated.
      #
      # @since 1.0.0
      def setup(klass)
        @klass = klass
      end

      # Validate the document for uniqueness violations.
      #
      # @example Validate the document.
      #   validate_each(person, :title, "Sir")
      #
      # @param [ Document ] document The document to validate.
      # @param [ Symbol ] attribute The field to validate on.
      # @param [ Object ] value The value of the field.
      #
      # @return [ Errors ] The errors.
      #
      # @since 1.0.0
      def validate_each(document, attribute, value)
        attrib, val = to_validate(document, attribute, value)
        return unless validation_required?(document, attrib)
        if document.embedded?
          validate_embedded(document, attrib, val)
        else
          validate_root(document, attrib, val)
        end
      end

      private

      # Add the error to the document.
      #
      # @api private
      #
      # @example Add the error.
      #   validator.add_error(doc, :name, "test")
      #
      # @param [ Document ] document The document to validate.
      # @param [ Symbol ] attribute The name of the attribute.
      # @param [ Object ] value The value of the object.
      #
      # @since 2.4.10
      def add_error(document, attribute, value)
        document.errors.add(
          attribute, :taken, options.except(:case_sensitive, :scope).merge(:value => value)
        )
      end

      # Should the uniqueness validation be case sensitive?
      #
      # @api private
      #
      # @example Is the validation case sensitive?
      #   validator.case_sensitive?
      #
      # @return [ true, false ] If the validation is case sensitive.
      #
      # @since 2.3.0
      def case_sensitive?
        !(options[:case_sensitive] == false)
      end

      # Create the validation criteria.
      #
      # @api private
      #
      # @example Create the criteria.
      #   validator.create_criteria(User, user, :name, "syd")
      #
      # @param [ Class, Proxy ] base The base to execute the criteria from.
      # @param [ Document ] document The document to validate.
      # @param [ Symbol ] attribute The name of the attribute.
      # @param [ Object ] value The value of the object.
      #
      # @return [ Criteria ] The criteria.
      #
      # @since 2.4.10
      def create_criteria(base, document, attribute, value)
        field = document.fields[attribute.to_s]
        criteria = base.paranoid ? base.unscoped.where(:deleted_at => nil) : base.unscoped
        if field.try(:localized?)
          criterion(document, attribute, value).each_pair do |key, value|
            criteria.selector.store(key, value)
          end
        else
          criteria = criteria.where(criterion(document, attribute, value))
        end
        scope(criteria, document, attribute)
      end

      # Get the default criteria for checking uniqueness.
      #
      # @api private
      #
      # @example Get the criteria.
      #   validator.criterion(person, :title, "Sir")
      #
      # @param [ Document ] document The document to validate.
      # @param [ Symbol ] attribute The name of the attribute.
      # @param [ Object ] value The value of the object.
      #
      # @return [ Criteria ] The uniqueness criteria.
      #
      # @since 2.3.0
      def criterion(document, attribute, value)
        { attribute => filter(value) }.tap do |selector|
          if document.persisted? && !document.embedded?
            selector.merge!(:_id => { "$ne" => document.id })
          end
        end
      end

      # Filter the value based on whether the check is case sensitive or not.
      #
      # @api private
      #
      # @example Filter the value.
      #   validator.filter("testing")
      #
      # @param [ Object ] value The value to filter.
      #
      # @return [ Object, Regexp ] The value, filtered or not.
      #
      # @since 2.3.0
      def filter(value)
        !case_sensitive? && value ? /^#{Regexp.escape(value.to_s)}$/i : value
      end

      # Scope the criteria to the scope options provided.
      #
      # @api private
      #
      # @example Scope the criteria.
      #   validator.scope(criteria, document)
      #
      # @param [ Criteria ] criteria The criteria to scope.
      # @param [ Document ] document The document being validated.
      #
      # @return [ Criteria ] The scoped criteria.
      #
      # @since 2.3.0
      def scope(criteria, document, attribute)
        Array.wrap(options[:scope]).each do |item|
          criteria = criteria.where(item => document.attributes[item.to_s])
        end
        criteria = criteria.where(:deleted_at => nil) if document.paranoid?
        criteria
      end

      # Should validation be skipped?
      #
      # @api private
      #
      # @example Should the validation be skipped?
      #   validator.skip_validation?(doc)
      #
      # @param [ Document ] document The embedded document.
      #
      # @return [ true, false ] If the validation should be skipped.
      #
      # @since 2.3.0
      def skip_validation?(document)
        !document._parent || document.embedded_one?
      end

      # Scope reference has changed?
      #
      # @api private
      #
      # @example Has scope reference changed?
      #   validator.scope_value_changed?(doc)
      #
      # @param [ Document ] document The embedded document.
      #
      # @return [ true, false ] If the scope reference has changed.
      #
      # @since
      def scope_value_changed?(document)
        Array.wrap(options[:scope]).any? do |item|
          document.send("attribute_changed?", item.to_s)
        end
      end

      # Get the name of the field and the value to validate. This is for the
      # case when we validate a relation via the relation name and not the key,
      # we need to send the key name and value to the db, not the relation
      # object.
      #
      # @api private
      #
      # @example Get the name and key to validate.
      #   validator.to_validate(doc, :parent, Parent.new)
      #
      # @param [ Document ] document The doc getting validated.
      # @param [ Symbol ] attribute The attribute getting validated.
      # @param [ Object ] value The value of the attribute.
      #
      # @return [ Array<Object, Object> ] The field and value.
      #
      # @since 2.4.4
      def to_validate(document, attribute, value)
        metadata = document.relations[attribute.to_s]
        if metadata && metadata.stores_foreign_key?
          [ metadata.foreign_key, value.id ]
        else
          [ attribute, value ]
        end
      end

      # Validate an embedded document.
      #
      # @api private
      #
      # @example Validate the embedded document.
      #   validator.validate_embedded(doc, :name, "test")
      #
      # @param [ Document ] document The document.
      # @param [ Symbol ] attribute The attribute name.
      # @param [ Object ] value The value.
      #
      # @since 2.4.10
      def validate_embedded(document, attribute, value)
        return if skip_validation?(document)
        relation = document._parent.send(document.metadata.name)
        criteria = create_criteria(relation, document, attribute, value)
        add_error(document, attribute, value) if criteria.count > 1
      end

      # Validate a root document.
      #
      # @api private
      #
      # @example Validate the root document.
      #   validator.validate_root(doc, :name, "test")
      #
      # @param [ Document ] document The document.
      # @param [ Symbol ] attribute The attribute name.
      # @param [ Object ] value The value.
      #
      # @since 2.4.10
      def validate_root(document, attribute, value)
        criteria = create_criteria(klass, document, attribute, value)
        add_error(document, attribute, value) if criteria.exists?
      end

      # Are we required to validate the document?
      #
      # @example Is validation needed?
      #   validator.validation_required?(doc, :field)
      #
      # @param [ Document ] document The document getting validated.
      # @param [ Symbol ] attribute The attribute to validate.
      #
      # @return [ true, false ] If we need to validate.
      #
      # @since 2.4.4
      def validation_required?(document, attribute)
        document.new_record? ||
          document.send("attribute_changed?", attribute.to_s) ||
          scope_value_changed?(document)
      end
    end
  end
end
