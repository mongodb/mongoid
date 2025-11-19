# frozen_string_literal: true

module Mongoid
  # Provides shared behavior for any document with "pluck" functionality.
  #
  # @api private
  module Pluckable
    extend ActiveSupport::Concern

    private

    # Prepares the field names for plucking by normalizing them to their
    # database field names. Also prepares a projection hash if requested.
    def prepare_pluck(field_names, document_class: klass, prepare_projection: false)
      normalized_field_names = []
      projection = {}

      field_names.each do |f|
        db_fn = document_class.database_field_name(f)
        normalized_field_names.push(db_fn)

        next unless prepare_projection

        cleaned_name = document_class.cleanse_localized_field_names(f)
        canonical_name = document_class.database_field_name(cleaned_name)
        projection[canonical_name] = true
      end

      { field_names: normalized_field_names, projection: projection }
    end

    # Plucks the given field names from the given documents.
    def pluck_from_documents(documents, field_names, document_class: klass)
      documents.reduce([]) do |plucked, doc|
        values = field_names.map { |name| extract_value(doc, name.to_s, document_class) }
        plucked << ((values.size == 1) ? values.first : values)
      end
    end

    # Fetch the element from the given hash and demongoize it using the
    # given field. If the obj is an array, map over it and call this method
    # on all of its elements.
    #
    # @param [ Hash | Array<Hash> ] obj The hash or array of hashes to fetch from.
    # @param [ String ] key The key to fetch from the hash.
    # @param [ Field ] field The field to use for demongoization.
    #
    # @return [ Object ] The demongoized value.
    def fetch_and_demongoize(obj, key, field)
      if obj.is_a?(Array)
        obj.map { |doc| fetch_and_demongoize(doc, key, field) }
      else
        value = obj.try(:fetch, key, nil)
        field ? field.demongoize(value) : value.class.demongoize(value)
      end
    end

    # Extracts the value for the given field name from the given attribute
    # hash.
    #
    # @param [ Hash ] attrs The attributes hash.
    # @param [ String ] field_name The name of the field to extract.
    #
    # @return [ Object ] The value for the given field name
    def extract_value(attrs, field_name, document_class)
      i = 1
      num_meths = field_name.count('.') + 1
      curr = attrs.dup

      document_class.traverse_association_tree(field_name) do |meth, obj, is_field|
        field = obj if is_field

        # use the correct document class to check for localized fields on
        # embedded documents.
        document_class = obj.klass if obj.respond_to?(:klass)

        is_translation = false
        # If no association or field was found, check if the meth is an
        # _translations field.
        if obj.nil? && (tr = meth.match(/(.*)_translations\z/)&.captures&.first)
          is_translation = true
          meth = document_class.database_field_name(tr)
        end

        curr = descend(curr, meth, field, num_meths, is_translation)

        i += 1
      end
      curr
    end

    # Descend one level in the attribute hash.
    #
    # @param [ Hash | Array<Hash> ] current The current level in the attribute hash.
    # @param [ String ] method_name The method name to descend to.
    # @param [ Field|nil ] field The field to use for demongoization.
    # @param [ Boolean ] is_translation Whether the method is an _translations field.
    # @param [ Integer ] part_count The total number of parts in the field name.
    #
    # @return [ Object ] The value at the next level.
    def descend(current, method_name, field, part_count, is_translation)
      # 1. If curr is an array fetch from all elements in the array.
      # 2. If the field is localized, and is not an _translations field
      #    (_translations fields don't show up in the fields hash).
      #    - If this is the end of the methods, return the translation for
      #      the current locale.
      #    - Otherwise, return the whole translations hash so the next method
      #      can select the language it wants.
      # 3. If the meth is an _translations field, do not demongoize the
      #    value so the full hash is returned.
      # 4. Otherwise, fetch and demongoize the value for the key meth.
      if current.is_a? Array
        res = fetch_and_demongoize(current, method_name, field)
        res.empty? ? nil : res
      elsif !is_translation && field&.localized?
        if i < part_count
          current.try(:fetch, method_name, nil)
        else
          fetch_and_demongoize(current, method_name, field)
        end
      elsif is_translation
        current.try(:fetch, method_name, nil)
      else
        fetch_and_demongoize(current, method_name, field)
      end
    end
  end
end
