# frozen_string_literal: true

module Mongoid
  module Validatable

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
    #
    # It is also possible to limit the uniqueness constraint to a set of
    # documents matching certain conditions:
    #   class Person
    #     include Mongoid::Document
    #     field :title
    #     field :active, type: Boolean
    #
    #     validates_uniqueness_of :title, conditions: -> {where(active: true)}
    #   end
    class UniquenessValidator < ActiveModel::EachValidator
      include Queryable

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
      def validate_each(document, attribute, value)
        with_query(document) do
          attrib, val = to_validate(document, attribute, value)
          return unless validation_required?(document, attrib)
          if document.embedded?
            validate_embedded(document, attrib, val)
          else
            validate_root(document, attrib, val)
          end
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
      def add_error(document, attribute, value)
        document.errors.add(
          attribute, :taken, **options.except(:case_sensitive, :scope).merge(value: value)
        )
      end

      # Should the uniqueness validation be case sensitive?
      #
      # @api private
      #
      # @example Is the validation case sensitive?
      #   validator.case_sensitive?
      #
      # @return [ true | false ] If the validation is case sensitive.
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
      # @param [ Class | Proxy ] base The base to execute the criteria from.
      # @param [ Document ] document The document to validate.
      # @param [ Symbol ] attribute The name of the attribute.
      # @param [ Object ] value The value of the object.
      #
      # @return [ Criteria ] The criteria.
      def create_criteria(base, document, attribute, value)
        criteria = scope(base.unscoped, document, attribute)
        field = document.fields[document.database_field_name(attribute)]

        # In the past, we were calling value.mongoize in all cases, which
        # would call Object's mongoize method. This is a problem for StringifiedSymbol,
        # because a Symbol should mongoize to a String, but calling .mongoize
        # on a Symbol mongoizes it to a Symbol.
        # Therefore, we call the field's mongoize in all cases except when the
        # field is localized, because by the time we arrive at this code, the
        # value is already in the form of { lang => translation } and calling
        # the field's mongoize will nest that further into { lang =>
        # "\{ lang => translation \}"} (assuming the field type is a string).
        # Therefore, we call Object's mongoize method so it returns the hash as
        # it is.
        mongoized = field.try(:localized?) ? value.mongoize : field.mongoize(value)
        criteria.selector.update(criterion(document, attribute, mongoized))
        criteria
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
      def criterion(document, attribute, value)
        field = document.database_field_name(attribute)

        if value && localized?(document, field)
          conditions = (value || {}).inject([]) { |acc, (k,v)| acc << { "#{field}.#{k}" => filter(v) }}
          selector = { "$or" => conditions }
        else
          selector = { field => filter(value) }
        end

        if document.persisted? && !document.embedded?
          selector.merge!(_id: { "$ne" => document._id })
        end
        selector
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
      # @return [ Object | Regexp ] The value, filtered or not.
      def filter(value)
        !case_sensitive? && value ? /\A#{Regexp.escape(value.to_s)}\z/i : value
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
      def scope(criteria, document, _attribute)
        Array.wrap(options[:scope]).each do |item|
          name = document.database_field_name(item)
          criteria = criteria.where(item => document.attributes[name])
        end
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
      # @return [ true | false ] If the validation should be skipped.
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
      # @return [ true | false ] If the scope reference has changed.
      def scope_value_changed?(document)
        Array.wrap(options[:scope]).any? do |item|
          document.send("attribute_changed?", item.to_s)
        end
      end

      # Get the name of the field and the value to validate. This is for the
      # case when we validate an association via the association name and not the key,
      # we need to send the key name and value to the db, not the association
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
      def to_validate(document, attribute, value)
        association = document.relations[attribute.to_s]
        if association && association.stores_foreign_key?
          [ association.foreign_key, value && value._id ]
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
      def validate_embedded(document, attribute, value)
        return if skip_validation?(document)
        relation = document._parent.send(document.association_name)
        criteria = create_criteria(relation, document, attribute, value)
        criteria = criteria.merge(options[:conditions].call) if options[:conditions]
        criteria = criteria.limit(2)
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
      def validate_root(document, attribute, value)
        klass = document.class

        while klass.superclass.respond_to?(:validators) && klass.superclass.validators.include?(self)
          klass = klass.superclass
        end
        criteria = create_criteria(klass, document, attribute, value)
        criteria = criteria.merge(options[:conditions].call) if options[:conditions]

        if criteria.read(mode: :primary).exists?
          add_error(document, attribute, value)
        end
      end

      # Are we required to validate the document?
      #
      # @example Is validation needed?
      #   validator.validation_required?(doc, :field)
      #
      # @param [ Document ] document The document getting validated.
      # @param [ Symbol ] attribute The attribute to validate.
      #
      # @return [ true | false ] If we need to validate.
      def validation_required?(document, attribute)
        document.new_record? ||
          document.send("attribute_changed?", attribute.to_s) ||
          scope_value_changed?(document)
      end

      # Is the attribute localized?
      #
      # @api private
      #
      # @example Is the attribute localized?
      #   validator.localized?(doc, :field)
      #
      # @param [ Document ] document The document getting validated.
      # @param [ Symbol ] attribute The attribute to validate.
      #
      # @return [ true | false ] If the attribute is localized.
      def localized?(document, attribute)
        document.fields[document.database_field_name(attribute)].try(:localized?)
      end
    end
  end
end
