# frozen_string_literal: true

module Mongoid
  module Attributes

    # This module contains the behavior for processing attributes.
    module Processing

      # Process the provided attributes casting them to their proper values if a
      # field exists for them on the document. This will be limited to only the
      # attributes provided in the supplied +Hash+ so that no extra nil values get
      # put into the document's attributes.
      #
      # @example Process the attributes.
      #   person.process_attributes(:title => "sir", :age => 40)
      #
      # @param [ Hash ] attrs The attributes to set.
      def process_attributes(attrs = nil)
        attrs ||= {}
        if !attrs.empty?

          # MONGOID-5308: Here we use #sanitize_for_mass_assignment to
          # preserve legacy behavior in case the user is using the
          # protected_attributes_continued gem. Note this is only
          # supported on the root document and not any nested attributes.
          attrs = sanitize_for_mass_assignment(attrs)

          attrs.each_pair do |key, value|
            next if pending_attribute?(key, value)
            process_attribute(key, value)
          end
        end
        yield self if block_given?
        process_pending
      end

      private

      # If the key provided is the name of an association or a nested attribute, we
      # need to wait until all other attributes are set before processing
      # these.
      #
      # @example Is the attribute pending?
      #   document.pending_attribute?(:name, "Durran")
      #
      # @param [ Symbol ] key The name of the attribute.
      # @param [ Object ] value The value of the attribute.
      #
      # @return [ true | false ] True if pending, false if not.
      def pending_attribute?(key, value)
        name = key.to_s

        aliased = if aliased_associations.key?(name)
          aliased_associations[name]
        else
          name
        end

        if relations.has_key?(aliased)
          pending_relations[name] = value
          return true
        end
        if nested_attributes.has_key?(aliased)
          pending_nested[name] = value
          return true
        end
        return false
      end

      # Get all the pending associations that need to be set.
      #
      # @example Get the pending associations.
      #   document.pending_relations
      #
      # @return [ Hash ] The pending associations in key/value pairs.
      def pending_relations
        @pending_relations ||= {}
      end

      # Get all the pending nested attributes that need to be set.
      #
      # @example Get the pending nested attributes.
      #   document.pending_nested
      #
      # @return [ Hash ] The pending nested attributes in key/value pairs.
      def pending_nested
        @pending_nested ||= {}
      end

      # If the attribute is dynamic, add a field for it with a type of object
      # and then either way set the value.
      #
      # @example Process the attribute.
      #   document.process_attribute(name, value)
      #
      # @param [ Symbol ] name The name of the field.
      # @param [ Object ] value The value of the field.
      def process_attribute(name, value)
        if !respond_to?("#{name}=", true) && store_as = aliased_fields.invert[name.to_s]
          name = store_as
        end
        responds = respond_to?("#{name}=", true)
        raise Errors::UnknownAttribute.new(self.class, name) unless responds
        send("#{name}=", value)
      end

      # Process all the pending nested attributes that needed to wait until
      # ids were set to fire off.
      #
      # @example Process the nested attributes.
      #   document.process_nested
      def process_nested
        pending_nested.each_pair do |name, value|
          value = sanitize_nested_forbidden_attributes(value)
          send("#{name}=", value)
        end
      end

      # Process all the pending items, then clear them out.
      #
      # @example Process the pending items.
      #   document.process_pending
      def process_pending
        process_nested and process_relations
        pending_nested.clear and pending_relations.clear
      end

      # Process all the pending associations that needed to wait until ids were set
      # to fire off.
      #
      # @example Process the associations.
      #   document.process_relations
      def process_relations
        pending_relations.each_pair do |name, value|
          association = relations[name]
          value = sanitize_nested_forbidden_attributes(value)
          if value.is_a?(Hash)
            association.nested_builder(value, {}).build(self)
          else
            send("#{name}=", value)
          end
        end
      end

      # Sanitize nested ActionController::Parameter objects, including
      # Array of ActionController::Parameter.
      # 
      # MONGOID-5308: Here we intentionally use #sanitize_forbidden_attributes
      # instead of #sanitize_for_mass_assignment. The former only resolves
      # Strong Parameters permitted attributes.
      def sanitize_nested_forbidden_attributes(attrs)
        if attrs.is_a?(Array)
          attrs.map(&method(:sanitize_forbidden_attributes))
        else
          sanitize_forbidden_attributes(attrs)
        end
      end
    end
  end
end
