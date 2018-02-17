# encoding: utf-8
module Mongoid
  module Association
    module Nested
      class Many
        include Buildable

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
        # @param [ Hash ] options The options.
        #
        # @return [ Array ] The attributes.
        def build(parent, options = {})
          @existing = parent.send(association.name)
          if over_limit?(attributes)
            raise Errors::TooManyNestedAttributeRecords.new(existing, options[:limit])
          end
          attributes.each do |attrs|
            if attrs.is_a?(::Hash)
              process_attributes(parent, attrs.with_indifferent_access)
            else
              process_attributes(parent, attrs[1].with_indifferent_access)
            end
          end
        end

        # Create the new builder for nested attributes on one-to-many
        # relations.
        #
        # @example Initialize the builder.
        #   Many.new(association, attributes, options)
        #
        # @param [ Association ] association The association metadata.
        # @param [ Hash ] attributes The attributes hash to attempt to set.
        # @param [ Hash ] options The options defined.
        def initialize(association, attributes, options = {})
          if attributes.respond_to?(:with_indifferent_access)
            @attributes = attributes.with_indifferent_access.sort do |a, b|
              a[0].to_i <=> b[0].to_i
            end
          else
            @attributes = attributes
          end
          @association = association
          @options = options
          @class_name = options[:class_name] ? options[:class_name].constantize : association.klass
        end

        private

        # Can the existing relation potentially be deleted?
        #
        # @example Is the document destroyable?
        #   destroyable?({ :_destroy => "1" })
        #
        # @param [ Hash ] attributes The attributes to pull the flag from.
        #
        # @return [ true, false ] If the relation can potentially be deleted.
        def destroyable?(attributes)
          destroy = attributes.delete(:_destroy)
          Nested::DESTROY_FLAGS.include?(destroy) && allow_destroy?
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
        #
        # @since 2.0.0
        def process_attributes(parent, attrs)
          return if reject?(parent, attrs)
          if id = attrs.extract_id
            update_nested_relation(parent, id, attrs)
          else
            existing.push(Factory.build(@class_name, attrs)) unless destroyable?(attrs)
          end
        end

        # Destroy the child document, needs to do some checking for embedded
        # relations and delay the destroy in case parent validation fails.
        #
        # @api private
        #
        # @example Destroy the child.
        #   builder.destroy(parent, relation, doc)
        #
        # @param [ Document ] parent The parent document.
        # @param [ Proxy ] relation The relation proxy.
        # @param [ Document ] doc The doc to destroy.
        #
        # @since 3.0.10
        def destroy(parent, relation, doc)
          doc.flagged_for_destroy = true
          if !doc.embedded? || parent.new_record?
            destroy_document(relation, doc)
          else
            parent.flagged_destroys.push(-> { destroy_document(relation, doc) })
          end
        end

        # Destroy the document.
        #
        # @api private
        #
        # @example Destroy the document.
        #   builder.destroy_document(relation, doc)
        #
        # @param [ Proxy ] relation The relation proxy.
        # @param [ Document ] doc The document to delete.
        #
        # @since 3.0.10
        def destroy_document(relation, doc)
          relation.delete(doc)
          doc.destroy unless doc.embedded? || doc.destroyed?
        end

        # Update the document.
        #
        # @api private
        #
        # @example Update the document.
        #   builder.update_document(doc, {}, options)
        #
        # @param [ Document ] doc The document to update.
        # @param [ Hash ] attrs The attributes.
        #
        # @since 3.0.10
        def update_document(doc, attrs)
          attrs.delete_id
          if association.embedded?
            doc.assign_attributes(attrs)
          else
            doc.update_attributes(attrs)
          end
        end

        # Update nested relation.
        #
        # @api private
        #
        # @example Update nested relation.
        #   builder.update_nested_relation(parent, id, attrs)
        #
        # @param [ Document ] parent The parent document.
        # @param [ String, BSON::ObjectId ] id of the related document.
        # @param [ Hash ] attrs The single document attributes to process.
        #
        # @since 6.0.0
        def update_nested_relation(parent, id, attrs)
          first = existing.first
          converted = first ? convert_id(first.class, id) : id

          if existing.where(id: converted).exists?
            # document exists in relation
            doc = existing.find(converted)
            if destroyable?(attrs)
              destroy(parent, existing, doc)
            else
              update_document(doc, attrs)
            end
          else
            # push existing document to relation
            doc = existing.unscoped.find(converted)
            update_document(doc, attrs)
            existing.push(doc) unless destroyable?(attrs)
          end
        end
      end
    end
  end
end
