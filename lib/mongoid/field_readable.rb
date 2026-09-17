# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  # Reads the value of a field name from a document without dispatching the
  # name as an arbitrary method.
  #
  # Field names may come from application input, where a name like +destroy+
  # or +attributes+ would delete the document or disclose its contents.
  # Declared field and association names are validated when they are declared
  # (see Mongoid.destructive_fields), so a name that resolves to one of them
  # is safe to send to a document. Any other name is read from the attributes
  # hash, which is what the database-backed query contexts do.
  #
  # @api private
  module FieldReadable
    private

    # Read the value of the given field name from the given document.
    #
    # @param [ Document ] document The document to read from.
    # @param [ String | Symbol ] name The name of the field.
    #
    # @return [ Object | nil ] The value of the field, or nil when the name
    #   is neither a declared field nor present in the attributes.
    def read_field_value(document, name)
      name = name.to_s
      # A blank name cannot name a field. Return nil, which is what reading
      # one has always done.
      return nil if name.blank?

      if (meth = readable_method_for(document.class, name))
        document.public_send(meth)
      else
        document.attributes[document.class.database_field_name(name)]
      end
    end

    # Resolve the given name to a method that is declared by the given class,
    # and therefore safe to send to one of its instances.
    #
    # @param [ Class ] klass The document class.
    # @param [ String ] name The name of the field.
    #
    # @return [ String | nil ] The method to send, or nil when the name is
    #   not declared by the class.
    def readable_method_for(klass, name)
      # Fields, associations, and field aliases each define a reader of their
      # own name. Note that associations must be resolved before aliases: a
      # belongs_to aliases its own name to its foreign key, and reading
      # `band` must give the document, not the id.
      return name if klass.relations.key?(name) ||
                     klass.fields.key?(name) ||
                     klass.aliased_fields.key?(name)

      # An association may also be named by its `store_as`, which has no
      # reader of its own, or by its ids accessor, which does.
      if (assoc = klass.relations[klass.aliased_associations[name]])
        return (assoc.store_as == name) ? assoc.name.to_s : name
      end

      # Localized fields also get a _translations reader, which does not
      # appear in the fields hash.
      base = name.delete_suffix(Fields::TRANSLATIONS_SFX)
      return nil if base == name

      name if klass.fields[klass.database_field_name(base)]&.localized?
    end
  end
end
