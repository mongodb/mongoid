# encoding: utf-8
module Mongoid
  module Attributes

    # This module contains the behavior for processing attributes.
    module Processing

      # Process the provided attributes casting them to their proper values if a
      # field exists for them on the document. This will be limited to only the
      # attributes provided in the suppied +Hash+ so that no extra nil values get
      # put into the document's attributes.
      #
      # @example Process the attributes.
      #   person.process_attributes(:title => "sir", :age => 40)
      #
      # @param [ Hash ] attrs The attributes to set.
      # @param [ Symbol ] role A role for scoped mass assignment.
      # @param [ Boolean ] guard_protected_attributes False to skip mass assignment protection.
      #
      # @since 2.0.0.rc.7
      def process_attributes(attrs = nil, role = :default, guard_protected_attributes = true)
        with_mass_assignment(role, guard_protected_attributes) do
          attrs ||= {}
          if !attrs.empty?
            attrs = sanitize_for_mass_assignment(attrs, role) if guard_protected_attributes
            attrs.each_pair do |key, value|
              next if pending_attribute?(key, value)
              process_attribute(key, value)
            end
          end
          yield self if block_given?
          process_pending
        end
      end

      private

      # Get the current mass assignment options for this model.
      #
      # @api private
      #
      # @return [ Hash ] The mass assignment options.
      #
      # @since 3.0.7
      def mass_assignment_options
        @mass_assignment_options ||= {}
      end

      # Set the mass assignment options for the current model.
      #
      # @api private
      #
      # @return [ Hash ] The mass assignment options.
      #
      # @since 3.0.7
      def mass_assignment_options=(options)
        @mass_assignment_options = options
      end

      # If the key provided is the name of a relation or a nested attribute, we
      # need to wait until all other attributes are set before processing
      # these.
      #
      # @example Is the attribute pending?
      #   document.pending_attribute?(:name, "Durran")
      #
      # @param [ Symbol ] key The name of the attribute.
      # @param [ Object ] value The value of the attribute.
      #
      # @return [ true, false ] True if pending, false if not.
      #
      # @since 2.0.0.rc.7
      def pending_attribute?(key, value)
        name = key.to_s
        if relations.has_key?(name)
          pending_relations[name] = value
          return true
        end
        if nested_attributes.has_key?(name)
          pending_nested[name] = value
          return true
        end
        return false
      end

      # Get all the pending relations that need to be set.
      #
      # @example Get the pending relations.
      #   document.pending_relations
      #
      # @return [ Hash ] The pending relations in key/value pairs.
      #
      # @since 2.0.0.rc.7
      def pending_relations
        @pending_relations ||= {}
      end

      # Get all the pending nested attributes that need to be set.
      #
      # @example Get the pending nested attributes.
      #   document.pending_nested
      #
      # @return [ Hash ] The pending nested attributes in key/value pairs.
      #
      # @since 2.0.0.rc.7
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
      #
      # @since 2.0.0.rc.7
      def process_attribute(name, value)
        writer_method = "#{name}="
        responds = respond_to?(writer_method)
        if Mongoid.allow_dynamic_fields && !responds
          write_attribute(name, value)
        else
          raise Errors::UnknownAttribute.new(self.class, name) unless responds
          send(writer_method, value)
        end
      end

      # Process all the pending nested attributes that needed to wait until
      # ids were set to fire off.
      #
      # @example Process the nested attributes.
      #   document.process_nested
      #
      # @since 2.0.0.rc.7
      def process_nested
        pending_nested.each_pair do |name, value|
          send("#{name}=", value)
        end
      end

      # Process all the pending items, then clear them out.
      #
      # @example Process the pending items.
      #   document.process_pending
      #
      # @param [ Hash ] options The mass assignment options.
      #
      # @since 2.0.0.rc.7
      def process_pending
        process_nested and process_relations
        pending_nested.clear and pending_relations.clear
      end

      # Process all the pending relations that needed to wait until ids were set
      # to fire off.
      #
      # @example Process the relations.
      #   document.process_relations
      #
      # @param [ Hash ] options The mass assignment options.
      #
      # @since 2.0.0.rc.7
      def process_relations
        pending_relations.each_pair do |name, value|
          metadata = relations[name]
          if value.is_a?(Hash)
            metadata.nested_builder(value, {}).build(self, mass_assignment_options)
          else
            send("#{name}=", value)
          end
        end
      end

      # Execute the block with the provided mass assignment options set.
      #
      # @api private
      #
      # @example Execute with mass assignment.
      #   model.with_mass_assignment(:default, true)
      #
      # @param [ Symbol ] role The role.
      # @param [ true, false ] guard_protected_attributes To enable mass
      #   assignment.
      #
      # @since 3.0.7
      def with_mass_assignment(role, guard_protected_attributes)
        begin
          self.mass_assignment_options =
            { as: role, without_protection: !guard_protected_attributes }
          yield
        ensure
          self.mass_assignment_options = nil
        end
      end
    end
  end
end
