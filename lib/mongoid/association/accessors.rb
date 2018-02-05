# encoding: utf-8
module Mongoid
  module Association

    # This module contains all the behaviour related to accessing relations
    # through the getters and setters, and how to delegate to builders to
    # create new ones.
    module Accessors
      extend ActiveSupport::Concern

      # Builds the related document and creates the relation unless the
      # document is nil, then sets the relation on this document.
      #
      # @example Build the relation.
      #   person.__build__(:addresses, { :_id => 1 }, association)
      #
      # @param [ String, Symbol ] name The name of the relation.
      # @param [ Hash, BSON::ObjectId ] object The id or attributes to use.
      # @param [ Association ] association The association metadata.
      #
      # @return [ Proxy ] The relation.
      #
      # @since 2.0.0.rc.1
      def __build__(name, object, association)
        relation = create_relation(object, association)
        set_relation(name, relation)
      end

      # Create a relation from an object and association.
      #
      # @example Create the relation.
      #   person.create_relation(document, association)
      #
      # @param [ Document, Array<Document> ] object The relation target.
      # @param [ Association ] association The association metadata.
      #
      # @return [ Proxy ] The relation.
      #
      # @since 2.0.0.rc.1
      def create_relation(object, association)
        type = @attributes[association.inverse_type]
        target = association.build(self, object, type)
        target ? association.create_relation(self, target) : nil
      end

      # Resets the criteria inside the relation proxy. Used by many-to-many
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
      #   document.get_relation(:name, association)
      #
      # @param [ Symbol ] name The name of the relation.
      # @param [ Association ] association The association metadata.
      # @param [ Object ] object The object used to build the relation.
      # @param [ true, false ] reload If the relation is to be reloaded.
      #
      # @return [ Proxy ] The relation.
      #
      # @since 3.0.16
      def get_relation(name, association, object, reload = false)
        if !reload && (value = ivar(name)) != false
          value
        else
          _building do
            _loading do
              if object && needs_no_database_query?(object, association)
                __build__(name, object, association)
              else
                __build__(name, attributes[association.key], association)
              end
            end
          end
        end
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

      # Parse out the attributes and the options from the args passed to a
      # build_ or create_ methods.
      #
      # @example Parse the args.
      #   doc.parse_args(:name => "Joe")
      #
      # @param [ Array ] args The arguments.
      #
      # @return [ Array<Hash> ] The attributes and options.
      #
      # @since 2.3.4
      def parse_args(*args)
        [args.first || {}, args.size > 1 ? args[1] : {}]
      end

      # Adds the existence check for relations.
      #
      # @example Add the existence check.
      #   Person.define_existence_check!(association)
      #
      # @example Check if a relation exists.
      #   person = Person.new
      #   person.has_game?
      #   person.game?
      #
      # @param [ Association ] association The association.
      #
      # @return [ Class ] The model being set up.
      #
      # @since 3.0.0
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

      # Defines the getter for the relation. Nothing too special here: just
      # return the instance variable for the relation if it exists or build
      # the thing.
      #
      # @example Set up the getter for the relation.
      #   Person.define_getter!(association)
      #
      # @param [ Association ] association The association metadata for the relation.
      #
      # @return [ Class ] The class being set up.
      #
      # @since 2.0.0.rc.1
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

      # Defines the getter for the ids of documents in the relation. Should
      # be specify only for referenced many relations.
      #
      # @example Set up the ids getter for the relation.
      #   Person.define_ids_getter!(association)
      #
      # @param [ Association ] association The association metadata for the relation.
      #
      # @return [ Class ] The class being set up.
      def self.define_ids_getter!(association)
        ids_method = "#{association.name.to_s.singularize}_ids"
        association.inverse_class.tap do |klass|
          klass.re_define_method(ids_method) do
            send(association.name).only(:id).map(&:id)
          end
        end
      end

      # Defines the setter for the relation. This does a few things based on
      # some conditions. If there is an existing association, a target
      # substitution will take place, otherwise a new relation will be
      # created with the supplied target.
      #
      # @example Set up the setter for the relation.
      #   Person.define_setter!(association)
      #
      # @param [ Association ] association The association metadata for the relation.
      #
      # @return [ Class ] The class being set up.
      #
      # @since 2.0.0.rc.1
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
      # in this relation by their ids. The defined setter, finds
      # documents with given ids and invokes regular relation setter
      # with found documents. Ids setters should be defined only for
      # referenced many relations.
      #
      # @example Set up the id_setter for the relation.
      #   Person.define_ids_setter!(association)
      #
      #  @param [ Association ] association The association for the relation.
      #
      #  @return [ Class ] The class being set up.
      def self.define_ids_setter!(association)
        ids_method = "#{association.name.to_s.singularize}_ids="
        association.inverse_class.tap do |klass|
          klass.re_define_method(ids_method) do |ids|
            send(association.setter, association.relation_class.find(ids.reject(&:blank?)))
          end
        end
      end

      # Defines a builder method for an embeds_one relation. This is
      # defined as #build_name.
      #
      # @example
      #   Person.define_builder!(association)
      #
      # @param [ Association ] association The association for the relation.
      #
      # @return [ Class ] The class being set up.
      #
      # @since 2.0.0.rc.1
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

      # Defines a creator method for an embeds_one relation. This is
      # defined as #create_name. After the object is built it will
      # immediately save.
      #
      # @example
      #   Person.define_creator!(association)
      #
      # @param [ Association ] association The association for the relation.
      #
      # @return [ Class ] The class being set up.
      #
      # @since 2.0.0.rc.1
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
