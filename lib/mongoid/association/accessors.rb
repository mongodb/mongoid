# frozen_string_literal: true

module Mongoid
  module Association

    # This module contains all the behavior related to accessing associations
    # through the getters and setters, and how to delegate to builders to
    # create new ones.
    module Accessors
      extend ActiveSupport::Concern

      # Builds the related document and creates the association unless the
      # document is nil, then sets the association on this document.
      #
      # @example Build the association.
      #   person.__build__(:addresses, { :_id => 1 }, association)
      #
      # @param [ String | Symbol ] name The name of the association.
      # @param [ Hash | BSON::ObjectId ] object The id or attributes to use.
      # @param [ Association ] association The association metadata.
      # @param [ Hash ] selected_fields Fields which were retrieved via #only.
      #   If selected_fields is specified, fields not listed in it will not be
      #   accessible in the built document.
      #
      # @return [ Proxy ] The association.
      def __build__(name, object, association, selected_fields = nil)
        relation = create_relation(object, association, selected_fields)
        set_relation(name, relation)
      end

      # Create an association from an object and association metadata.
      #
      # @example Create the association.
      #   person.create_relation(document, association)
      #
      # @param [ Document | Array<Document> ] object The association target.
      # @param [ Association ] association The association metadata.
      # @param [ Hash ] selected_fields Fields which were retrieved via #only.
      #   If selected_fields is specified, fields not listed in it will not be
      #   accessible in the created association document.
      #
      # @return [ Proxy ] The association.
      def create_relation(object, association, selected_fields = nil)
        type = @attributes[association.inverse_type]
        target = if t = association.build(self, object, type, selected_fields)
          association.create_relation(self, t)
        else
          nil
        end

        # Only need to do this on embedded associations. The pending callbacks
        # are only added when materializing the documents, which only happens
        # on embedded associations. There is no call to the database in the
        # construction of a referenced association.
        if association.embedded?
          Array(target).each do |doc|
            doc.try(:run_pending_callbacks)
          end
        end

        target
      end

      # Resets the criteria inside the association proxy. Used by many-to-many
      # associations to keep the underlying ids array in sync.
      #
      # @example Reset the association criteria.
      #   person.reset_relation_criteria(:preferences)
      #
      # @param [ Symbol ] name The name of the association.
      def reset_relation_criteria(name)
        if instance_variable_defined?("@_#{name}")
          send(name).reset_unloaded
        end
      end

      # Set the supplied association to an instance variable on the class with the
      # provided name. Used as a helper just for code cleanliness.
      #
      # @example Set the proxy on the document.
      #   person.set(:addresses, addresses)
      #
      # @param [ String | Symbol ] name The name of the association.
      # @param [ Proxy ] relation The association to set.
      #
      # @return [ Proxy ] The association.
      def set_relation(name, relation)
        instance_variable_set("@_#{name}", relation)
      end

      private

      # Get the association. Extracted out from the getter method to avoid
      # infinite recursion when overriding the getter.
      #
      # @api private
      #
      # @example Get the association.
      #   document.get_relation(:name, association)
      #
      # @param [ Symbol ] name The name of the association.
      # @param [ Association ] association The association metadata.
      # @param [ Object ] object The object used to build the association.
      # @param [ true | false ] reload If the association is to be reloaded.
      #
      # @return [ Proxy ] The association.
      def get_relation(name, association, object, reload = false)
        field_name = database_field_name(name)

        # As per the comments under MONGOID-5034, I've decided to only raise on
        # embedded associations for a missing attribute. Rails does not raise
        # for a missing attribute on referenced associations.
        # We also don't want to raise if we're retrieving an association within
        # the codebase. This is often done when retrieving the inverse association
        # during binding or when cascading callbacks. Whenever we retrieve
        # associations within the codebase, we use without_autobuild.
        if !without_autobuild? && association.embedded? && attribute_missing?(field_name)
          raise ActiveModel::MissingAttributeError, "Missing attribute: '#{field_name}'"
        end

        if !reload && (value = ivar(name)) != false
          value
        else
          _building do
            _loading do
              if object && needs_no_database_query?(object, association)
                __build__(name, object, association)
              else
                selected_fields = _mongoid_filter_selected_fields(association.key)
                __build__(name, attributes[association.key], association, selected_fields)
              end
            end
          end
        end
      end

      # Returns a subset of __selected_fields attribute applicable to the
      # (embedded) association with the given key, or nil if no projection
      # is to be performed.
      #
      # Also returns nil if exclusionary projection was requested but it does
      # not exclude the field of the association.
      #
      # For example, if __selected_fields is {'a' => 1, 'b.c' => 2, 'b.c.f' => 3},
      # and assoc_key is 'b', return value would be {'c' => 2, 'c.f' => 3}.
      #
      # @param [ String ] assoc_key
      #
      # @return [ Hash | nil ]
      #
      # @api private
      def _mongoid_filter_selected_fields(assoc_key)
        return nil unless __selected_fields

        # If the list of fields was specified using #without instead of #only
        # and the provided list does not include the association, any of its
        # fields should be allowed.
        if __selected_fields.values.all? { |v| v == 0 } &&
          __selected_fields.keys.none? { |k| k.split('.', 2).first == assoc_key }
        then
          return nil
        end

        projecting_assoc = false

        filtered = {}
        __selected_fields.each do |k, v|
          bits = k.split('.')

          # If we are asked to project an association, we need all of that
          # association's fields. However, we may be asked to project
          # an association *and* its fields in the same query. In this case
          # behavior differs according to server version:
          #
          # 4.2 and lower take the most recent projection specification, meaning
          # projecting foo followed by foo.bar effectively projects foo.bar and
          # projecting foo.bar followed by foo effectively projects foo.
          # To match this behavior we need to track when we are being asked
          # to project the association and when we are asked to project a field,
          # and if we are asked to project the association last we need to
          # remove any field projections.
          #
          # 4.4 (and presumably higher) do not allow projection to be on an
          # association and its field, so it doesn't matter what we do. Hence
          # we just need to handle the 4.2 and lower case correctly.
          if bits.first == assoc_key
            # Projecting the entire association OR some of its fields
            if bits.length > 1
              # Projecting a field
              bits.shift
              filtered[bits.join('.')] = v
              projecting_assoc = false
            else
              # Projecting the entire association
              projecting_assoc = true
            end
          end
        end

        if projecting_assoc
          # The last projection was of the entire association; we may have
          # also been projecting fields, but discard the field projections
          # and return nil indicating we want the entire association.
          return nil
        end

        # Positional projection is specified as "foo.$". In this case the
        # document that the $ is referring to should be retrieved with all
        # fields. See https://www.mongodb.com/docs/manual/reference/operator/projection/positional/
        # and https://jira.mongodb.org/browse/MONGOID-4769.
        if filtered.keys == %w($)
          filtered = nil
        end

        filtered
      end

      def needs_no_database_query?(object, association)
        object.is_a?(Document) && !object.embedded? &&
            object._id == attributes[association.key]
      end

      # Is the current code executing without autobuild functionality?
      #
      # @example Is autobuild disabled?
      #   document.without_autobuild?
      #
      # @return [ true | false ] If autobuild is disabled.
      def without_autobuild?
        Threaded.executing?(:without_autobuild)
      end

      # Yield to the block with autobuild functionality turned off.
      #
      # @example Execute without autobuild.
      #   document.without_autobuild do
      #     document.name
      #   end
      #
      # @return [ Object ] The result of the yield.
      def without_autobuild
        Threaded.begin_execution("without_autobuild")
        yield
      ensure
        Threaded.exit_execution("without_autobuild")
      end

      # Parse out the attributes and the options from the args passed to a
      # build_ or create_ methods.
      #
      # @example Parse the args.
      #   doc.parse_args(:name => "Joe")
      #
      # @param [ Hash... ] *args The arguments.
      #
      # @return [ Array<Hash> ] The attributes and options.
      def parse_args(*args)
        [args.first || {}, args.size > 1 ? args[1] : {}]
      end

      # Adds the existence check for associations.
      #
      # @example Add the existence check.
      #   Person.define_existence_check!(association)
      #
      # @example Check if an association exists.
      #   person = Person.new
      #   person.has_game?
      #   person.game?
      #
      # @param [ Association ] association The association.
      #
      # @return [ Class ] The model being set up.
      def self.define_existence_check!(association)
        name = association.name
        association.inverse_class.tap do |klass|
          klass.module_eval <<-END, __FILE__, __LINE__ + 1
              def #{name}?
                without_autobuild { !__send__(:#{name}).blank? }
              end
              alias :has_#{name}? :#{name}?
          END
        end
      end

      # Defines the getter for the association. Nothing too special here: just
      # return the instance variable for the association if it exists or build
      # the thing.
      #
      # @example Set up the getter for the association.
      #   Person.define_getter!(association)
      #
      # @param [ Association ] association The association metadata for the association.
      #
      # @return [ Class ] The class being set up.
      def self.define_getter!(association)
        name = association.name
        association.inverse_class.tap do |klass|
          klass.re_define_method(name) do |reload = false|
            value = get_relation(name, association, nil, reload)
            if value.nil? && association.autobuilding? && !without_autobuild?
              value = send("build_#{name}")
            end
            value
          end
        end
      end

      # Defines the getter for the ids of documents in the association. Should
      # be specify only for referenced many associations.
      #
      # @example Set up the ids getter for the association.
      #   Person.define_ids_getter!(association)
      #
      # @param [ Association ] association The association metadata for the association.
      #
      # @return [ Class ] The class being set up.
      def self.define_ids_getter!(association)
        ids_method = "#{association.name.to_s.singularize}_ids"
        association.inverse_class.tap do |klass|
          klass.re_define_method(ids_method) do
            send(association.name).pluck(:_id)
          end
        end
      end

      # Defines the setter for the association. This does a few things based on
      # some conditions. If there is an existing association, a target
      # substitution will take place, otherwise a new association will be
      # created with the supplied target.
      #
      # @example Set up the setter for the association.
      #   Person.define_setter!(association)
      #
      # @param [ Association ] association The association metadata for the association.
      #
      # @return [ Class ] The class being set up.
      def self.define_setter!(association)
        name = association.name
        association.inverse_class.tap do |klass|
          klass.re_define_method("#{name}=") do |object|
            without_autobuild do
              if value = get_relation(name, association, object)
                if value.respond_to?(:substitute)
                  set_relation(name, value.substitute(object.substitutable))
                else
                  value = __build__(name, value, association)
                  set_relation(name, value.substitute(object.substitutable))
                end
              else
                __build__(name, object.substitutable, association)
              end
            end
          end
        end
      end

      # Defines the setter method that allows you to set documents
      # in this association by their ids. The defined setter, finds
      # documents with given ids and invokes regular association setter
      # with found documents. Ids setters should be defined only for
      # referenced many associations.
      #
      # @example Set up the id_setter for the association.
      #   Person.define_ids_setter!(association)
      #
      #  @param [ Association ] association The association for the association.
      #
      #  @return [ Class ] The class being set up.
      def self.define_ids_setter!(association)
        ids_method = "#{association.name.to_s.singularize}_ids="
        association.inverse_class.aliased_associations[ids_method.chop] = association.name.to_s
        association.inverse_class.tap do |klass|
          klass.re_define_method(ids_method) do |ids|
            send(association.setter, association.relation_class.find(ids.reject(&:blank?)))
          end
        end
      end

      # Defines a builder method for an embeds_one association. This is
      # defined as #build_name.
      #
      # @example
      #   Person.define_builder!(association)
      #
      # @param [ Association ] association The association for the association.
      #
      # @return [ Class ] The class being set up.
      def self.define_builder!(association)
        name = association.name
        association.inverse_class.tap do |klass|
          klass.re_define_method("build_#{name}") do |*args|
            attributes, _options = parse_args(*args)
            document = Factory.build(association.relation_class, attributes)
            _building do
              child = send("#{name}=", document)
              child.run_callbacks(:build)
              child
            end
          end
        end
      end

      # Defines a creator method for an embeds_one association. This is
      # defined as #create_name. After the object is built it will
      # immediately save.
      #
      # @example
      #   Person.define_creator!(association)
      #
      # @param [ Association ] association The association for the association.
      #
      # @return [ Class ] The class being set up.
      def self.define_creator!(association)
        name = association.name
        association.inverse_class.tap do |klass|
          klass.re_define_method("create_#{name}") do |*args|
            attributes, _options = parse_args(*args)
            document = Factory.build(association.klass, attributes)
            doc = _assigning do
              send("#{name}=", document)
            end
            doc.save
            save if new_record? && association.stores_foreign_key?
            doc
          end
        end
      end
    end
  end
end
