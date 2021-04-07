module Mongoid

  # @api private
  module Matcher

    # Extracts field values in the document at the specified key.
    #
    # The document can be a Hash or a model instance.
    #
    # The key is a valid MongoDB dot notation key. The following use cases are
    # supported:
    #
    # - Simple field traversal (`foo`) - retrieves the field `foo` in the
    #   current document.
    # - Hash/embedded document field traversal (`foo.bar`) - retrieves the
    #   field `foo` in the current document, then retrieves the field `bar`
    #   from the value of `foo`. Each path segment could descend into an
    #   embedded document or a hash field.
    # - Array element retrieval (`foo.N`) - retrieves the Nth array element
    #   from the field `foo` which must be an array. N must be a non-negative
    #   integer.
    # - Array traversal (`foo.bar`) - if `foo` is an array field, and
    #   the elements of `foo` are hashes or embedded documents, this returns
    #   an array of values of the `bar` field in each of the hashes in the
    #   `foo` array.
    #
    # The return value is a two-element array. The first element is the value
    # retrieved, or an array of values. The second element is a boolean flag
    # indicating whether an array was expanded at any point during the key
    # traversal (because the respective document field was an array).
    #
    # @param [ Document | Hash ] document The document to extract from.
    # @param [ String ] key The key path to extract.
    #
    # @return [ Array<true | false, Object | Array, true | false> ]
    #   Whether the value existed in the document, the extracted value
    #   and the array expansion flag.
    module_function def extract_attribute(document, key)
      if document.respond_to?(:as_attributes, true)
        # If a document has hash fields, as_attributes would keep those fields
        # as Hash instances which do not offer indifferent access.
        # Convert to BSON::Document to get indifferent access on hash fields.
        document = BSON::Document.new(document.send(:as_attributes))
      end

      current = [document]

      key.to_s.split('.').each do |field|
        new = []
        current.each do |doc|
          case doc
          when Hash
            if doc.key?(field)
              new << doc[field]
            end
          when Array
            if (index = field.to_i).to_s == field
              if doc.length > index
                new << doc[index]
              end
            end
            doc.each do |subdoc|
              if Hash === subdoc
                if subdoc.key?(field)
                  new << subdoc[field]
                end
              end
            end
          end
        end
        current = new
        break if current.empty?
      end

      current
    end
  end
end

require 'mongoid/matcher/all'
require 'mongoid/matcher/and'
require 'mongoid/matcher/bits'
require 'mongoid/matcher/bits_all_clear'
require 'mongoid/matcher/bits_all_set'
require 'mongoid/matcher/bits_any_clear'
require 'mongoid/matcher/bits_any_set'
require 'mongoid/matcher/elem_match'
require 'mongoid/matcher/elem_match_expression'
require 'mongoid/matcher/eq'
require 'mongoid/matcher/eq_impl'
require 'mongoid/matcher/eq_impl_with_regexp'
require 'mongoid/matcher/exists'
require 'mongoid/matcher/expression'
require 'mongoid/matcher/field_expression'
require 'mongoid/matcher/gt'
require 'mongoid/matcher/gte'
require 'mongoid/matcher/in'
require 'mongoid/matcher/lt'
require 'mongoid/matcher/lte'
require 'mongoid/matcher/mod'
require 'mongoid/matcher/ne'
require 'mongoid/matcher/nin'
require 'mongoid/matcher/nor'
require 'mongoid/matcher/not'
require 'mongoid/matcher/or'
require 'mongoid/matcher/regex'
require 'mongoid/matcher/size'
require 'mongoid/matcher/type'
require 'mongoid/matcher/expression_operator'
require 'mongoid/matcher/field_operator'
