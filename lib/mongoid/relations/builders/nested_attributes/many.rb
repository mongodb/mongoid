# encoding: utf-8
module Mongoid
  module Relations
    module Builders
      module NestedAttributes
        class Many < NestedBuilder

          # Builds the relation depending on the attributes and the options
          # passed to the macro.
          #
          # This attempts to perform 3 operations, either one of an update of
          # the existing relation, a replacement of the relation with a new
          # document, or a removal of the relation.
          #
          # @example Build the nested attrs.
          #   many.build(person)
          #
          # @param [ Document ] parent The parent document of the relation.
          # @param [ Hash ] options The mass assignment options.
          #
          # @return [ Array ] The attributes.
          def build(parent, options = {})
            @existing = parent.send(metadata.name)
            if over_limit?(attributes)
              raise Errors::TooManyNestedAttributeRecords.new(existing, options[:limit])
            end
            attributes.each do |attrs|
              if attrs.respond_to?(:with_indifferent_access)
                process_attributes(parent, attrs, options)
              else
                process_attributes(parent, attrs[1], options)
              end
            end
          end

          # Create the new builder for nested attributes on one-to-many
          # relations.
          #
          # @example Initialize the builder.
          #   One.new(metadata, attributes, options)
          #
          # @param [ Metadata ] metadata The relation metadata.
          # @param [ Hash ] attributes The attributes hash to attempt to set.
          # @param [ Hash ] options The options defined.
          def initialize(metadata, attributes, options = {})
            if attributes.respond_to?(:with_indifferent_access)
              @attributes = attributes.with_indifferent_access.sort do |a, b|
                a[0].to_i <=> b[0].to_i
              end
            else
              @attributes = attributes
            end
            @metadata = metadata
            @options = options
          end

          private

          # Can the existing relation potentially be deleted?
          #
          # @example Is the document destroyable?
          #   destroyable?({ :_destroy => "1" })
          #
          # @parma [ Hash ] attributes The attributes to pull the flag from.
          #
          # @return [ true, false ] If the relation can potentially be deleted.
          def destroyable?(attributes)
            destroy = attributes.delete(:_destroy)
            [ 1, "1", true, "true" ].include?(destroy) && allow_destroy?
          end

          # Are the supplied attributes of greater number than the supplied
          # limit?
          #
          # @example Are we over the set limit?
          #   builder.over_limit?({ "street" => "Bond" })
          #
          # @param [ Hash ] attributes The attributes being set.
          #
          # @return [ true, false ] If the attributes exceed the limit.
          def over_limit?(attributes)
            limit = options[:limit]
            limit ? attributes.size > limit : false
          end

          # Process each set of attributes one at a time for each potential
          # new, existing, or ignored document.
          #
          # @api private
          #
          # @example Process the attributes
          #   builder.process_attributes({ "id" => 1, "street" => "Bond" })
          #
          # @param [ Document ] parent The parent document.
          # @param [ Hash ] attrs The single document attributes to process.
          # @param [ Hash ] options the mass assignment options.
          #
          # @since 2.0.0
          def process_attributes(parent, attrs, options)
            return if reject?(parent, attrs)
            if id = attrs.extract_id
              first = existing.first
              converted = first ? convert_id(first.class, id) : id
              doc = existing.find(converted)
              if destroyable?(attrs)
                doc.flagged_for_destroy = true
                parent.flagged_destroys.push(->{
                  existing.delete(doc)
                  doc.destroy unless doc.embedded? || doc.destroyed?
                })
              else
                attrs.delete_id
                if metadata.embedded?
                  doc.assign_attributes(attrs, options)
                else
                  doc.update_attributes(attrs, options)
                end
              end
            else
              existing.push(Factory.build(metadata.klass, attrs, options)) unless destroyable?(attrs)
            end
          end
        end
      end
    end
  end
end
