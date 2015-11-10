# encoding: utf-8
module Mongoid
  module Relations

    # This module contains all the behaviour related to accessing relations
    # through the getters and setters, and how to delegate to builders to
    # create new ones.
    module Accessors
      extend ActiveSupport::Concern

      # Builds the related document and creates the relation unless the
      # document is nil, then sets the relation on this document.
      #
      # @example Build the relation.
      #   person.__build__(:addresses, { :_id => 1 }, metadata)
      #
      # @param [ String, Symbol ] name The name of the relation.
      # @param [ Hash, BSON::ObjectId ] object The id or attributes to use.
      # @param [ Metadata ] metadata The relation's metadata.
      # @param [ true, false ] building If we are in a build operation.
      #
      # @return [ Proxy ] The relation.
      #
      # @since 2.0.0.rc.1
      def __build__(name, object, metadata)
        relation = create_relation(object, metadata)
        set_relation(name, relation)
      end

      # Create a relation from an object and metadata.
      #
      # @example Create the relation.
      #   person.create_relation(document, metadata)
      #
      # @param [ Document, Array<Document ] object The relation target.
      # @param [ Metadata ] metadata The relation metadata.
      #
      # @return [ Proxy ] The relation.
      #
      # @since 2.0.0.rc.1
      def create_relation(object, metadata)
        type = @attributes[metadata.inverse_type]
        target = metadata.builder(self, object).build(type)
        target ? metadata.relation.new(self, target, metadata) : nil
      end

      # Resets the criteria inside the relation proxy. Used by many to many
      # relations to keep the underlying ids array in sync.
      #
      # @example Reset the relation criteria.
      #   person.reset_relation_criteria(:preferences)
      #
      # @param [ Symbol ] name The name of the relation.
      #
      # @since 3.0.14
      def reset_relation_criteria(name)
        if instance_variable_defined?("@_#{name}")
          send(name).reset_unloaded
        end
      end

      # Set the supplied relation to an instance variable on the class with the
      # provided name. Used as a helper just for code cleanliness.
      #
      # @example Set the proxy on the document.
      #   person.set(:addresses, addresses)
      #
      # @param [ String, Symbol ] name The name of the relation.
      # @param [ Proxy ] relation The relation to set.
      #
      # @return [ Proxy ] The relation.
      #
      # @since 2.0.0.rc.1
      def set_relation(name, relation)
        instance_variable_set("@_#{name}", relation)
      end

      private

      # Get the relation. Extracted out from the getter method to avoid
      # infinite recursion when overriding the getter.
      #
      # @api private
      #
      # @example Get the relation.
      #   document.get_relation(:name, metadata)
      #
      # @param [ Symbol ] name The name of the relation.
      # @param [ Metadata ] metadata The relation metadata.
      # @param [ true, false ] reload If the relation is to be reloaded.
      #
      # @return [ Proxy ] The relation.
      #
      # @since 3.0.16
      def get_relation(name, metadata, object, reload = false)
        if !reload && (value = ivar(name)) != false
          value
        else
          _building do
            _loading do
              if object && needs_no_database_query?(object, metadata)
                __build__(name, object, metadata)
              else
                __build__(name, attributes[metadata.key], metadata)
              end
            end
          end
        end
      end

      def needs_no_database_query?(object, metadata)
        object.is_a?(Document) && !object.embedded? &&
          object._id == attributes[metadata.key]
      end

      # Is the current code executing without autobuild functionality?
      #
      # @example Is autobuild disabled?
      #   document.without_autobuild?
      #
      # @return [ true, false ] If autobuild is disabled.
      #
      # @since 3.0.0
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
      #
      # @since 3.0.0
      def without_autobuild
        Threaded.begin_execution("without_autobuild")
        yield
      ensure
        Threaded.exit_execution("without_autobuild")
      end

      module ClassMethods

        # Adds the existence check for relations.
        #
        # @example Add the existence check.
        #   Person.existence_check(:name, meta)
        #
        # @example Check if a relation exists.
        #   person = Person.new
        #   person.has_game?
        #   person.game?
        #
        # @param [ String, Symbol ] name The name of the relation.
        #
        # @return [ Class ] The model being set up.
        #
        # @since 3.0.0
        def existence_check(name)
          module_eval <<-END
            def #{name}?
              without_autobuild { !__send__(:#{name}).blank? }
            end
            alias :has_#{name}? :#{name}?
          END
          self
        end

        # Defines the getter for the relation. Nothing too special here: just
        # return the instance variable for the relation if it exists or build
        # the thing.
        #
        # @example Set up the getter for the relation.
        #   Person.getter("addresses", metadata)
        #
        # @param [ String, Symbol ] name The name of the relation.
        # @param [ Metadata ] metadata The metadata for the relation.
        #
        # @return [ Class ] The class being set up.
        #
        # @since 2.0.0.rc.1
        def getter(name, metadata)
          re_define_method(name) do |reload = false|
            value = get_relation(name, metadata, nil, reload)
            if value.nil? && metadata.autobuilding? && !without_autobuild?
              value = send("build_#{name}")
            end
            value
          end
          self
        end

        # Defines the getter for the ids of documents in the relation. Should
        # be specify only for referenced many relations.
        #
        # @example Set up the ids getter for the relation.
        #   Person.ids_getter("addresses", metadata)
        #
        # @param [ String, Symbol ] name The name of the relation.
        #
        # @return [ Class ] The class being set up.
        def ids_getter(name, metadata)
          ids_method = "#{name.to_s.singularize}_ids"
          re_define_method(ids_method) do
            send(name).only(:id).map(&:id)
          end
          self
        end

        # Defines the setter for the relation. This does a few things based on
        # some conditions. If there is an existing association, a target
        # substitution will take place, otherwise a new relation will be
        # created with the supplied target.
        #
        # @example Set up the setter for the relation.
        #   Person.setter("addresses", metadata)
        #
        # @param [ String, Symbol ] name The name of the relation.
        # @param [ Metadata ] metadata The metadata for the relation.
        #
        # @return [ Class ] The class being set up.
        #
        # @since 2.0.0.rc.1
        def setter(name, metadata)
          re_define_method("#{name}=") do |object|
            without_autobuild do
              if value = get_relation(name, metadata, object)
                if value.respond_to?(:substitute)
                  set_relation(name, value.substitute(object.substitutable))
                end
              else
                __build__(name, object.substitutable, metadata)
              end
            end
          end
          self
        end

        # Defines the setter method that allows you to set documents
        # in this relation by their ids. The defined setter, finds
        # documents with given ids and invokes regular relation setter
        # with found documents. Ids setters should be defined only for
        # referenced many relations.
        #
        # @example Set up the id_setter for the relation.
        #   Person.ids_setter("addesses", metadata)
        #
        #  @param [ String, Symbol ] name The name of the relation.
        #  @param [ Metadata ] metadata The metadata for the relation.
        #
        #  @return [ Class ] The class being set up.
        def ids_setter(name, metadata)
          ids_method = "#{name.to_s.singularize}_ids="
          re_define_method(ids_method) do |ids|
            send(metadata.setter, metadata.klass.find(ids.reject(&:blank?)))
          end
          self
        end
      end
    end
  end
end
