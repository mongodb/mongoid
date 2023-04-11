# frozen_string_literal: true

module Mongoid
  module Contextual
    class Mongo

      # Utility class to add enumerable behavior for Criteria#pluck_each.
      #
      # @api private
      class PluckEnumerator
        include Enumerable

        # Create the new PluckEnumerator.
        #
        # @api private
        #
        # @example Initialize a PluckEnumerator.
        #   PluckEnumerator.new(klass, view, fields)
        #
        # @param [ Class ] klass The base of the binding.
        # @param [ Mongo::Collection::View ] view The Mongo view context.
        # @param [ String | Symbol ] *fields Field(s) to pluck,
        #   which may include nested fields using dot-notation.
        def initialize(klass, view, fields)
          @klass = klass
          @view = view
          @fields = fields
        end

        # Iterate through plucked field value(s) from the database
        # for the view context. Yields result values progressively as
        # they are read from the database. The yielded results are
        # normalized according to their Mongoid field types.
        #
        # @api private
        #
        # @example Iterate through the plucked values from the database.
        #   context.pluck_each(:name) { |name| puts name }
        #
        # @param [ Proc ] &block The block to call once for each plucked
        #   result.
        #
        # @return [ Enumerator | PluckEnumerator ] The enumerator, or
        #   self if a block was given.
        def each(&block)
          return to_enum unless block_given?

          @view.projection(normalized_field_names.index_with(true)).each do |doc|
            yield_result(doc, &block)
          end

          self
        end

        private

        def database_field_names
          @database_field_names ||= @fields.map {|f| @klass.database_field_name(f) }
        end

        def normalized_field_names
          @normalized_field_names ||= @fields.map {|f| @klass.cleanse_localized_field_names(f) }
        end

        def yield_result(doc)
          values = database_field_names.map {|n| extract_value(doc, n) }
          yield(values.size == 1 ? values.first : values)
        end

        # Fetch the element from the given hash and demongoize it using the
        # given field. If the obj is an array, map over it and call this method
        # on all of its elements.
        #
        # @param [ Hash | Array<Hash> ] obj The hash or array of hashes to fetch from.
        # @param [ String ] meth The key to fetch from the hash.
        # @param [ Field ] field The field to use for demongoization.
        #
        # @return [ Object ] The demongoized value.
        #
        # @api private
        def fetch_and_demongoize(obj, meth, field)
          if obj.is_a?(Array)
            obj.map { |doc| fetch_and_demongoize(doc, meth, field) }
          else
            res = obj.try(:fetch, meth, nil)
            field ? field.demongoize(res) : res.class.demongoize(res)
          end
        end

        # Extracts the value for the given field name from the given attribute
        # hash.
        #
        # @param [ Hash ] attrs The attributes hash.
        # @param [ String ] field_name The name of the field to extract.
        #
        # @return [ Object ] The value for the given field name
        #
        # @api private
        def extract_value(attrs, field_name)
          i = 1
          num_meths = field_name.count('.') + 1
          curr = attrs.dup

          @klass.traverse_association_tree(field_name) do |meth, obj, is_field|
            field = obj if is_field
            is_translation = false
            # If no association or field was found, check if the meth is an
            # _translations field.
            if obj.nil? & tr = meth.match(/(.*)_translations\z/)&.captures&.first
              is_translation = true
              meth = tr
            end

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
            curr = if curr.is_a? Array
              res = fetch_and_demongoize(curr, meth, field)
              res.empty? ? nil : res
            elsif !is_translation && field&.localized?
              if i < num_meths
                curr.try(:fetch, meth, nil)
              else
                fetch_and_demongoize(curr, meth, field)
              end
            elsif is_translation
              curr.try(:fetch, meth, nil)
            else
              fetch_and_demongoize(curr, meth, field)
            end

            i += 1
          end

          curr
        end
      end
    end
  end
end
