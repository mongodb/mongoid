# frozen_string_literal: true

require 'mongoid/positional'
require 'mongoid/evolvable'
require 'mongoid/extensions'
require 'mongoid/errors'
require 'mongoid/threaded'
require 'mongoid/atomic'
require 'mongoid/attributes'
require 'mongoid/contextual'
require 'mongoid/copyable'
require 'mongoid/equality'
require 'mongoid/criteria'
require 'mongoid/factory'
require 'mongoid/fields'
require 'mongoid/timestamps'
require 'mongoid/association'
require 'mongoid/composable'
require 'mongoid/touchable'

module Mongoid
  # This is the base module for all domain objects that need to be persisted to
  # the database as documents.
  module Document
    extend ActiveSupport::Concern
    include Composable
    include Mongoid::Touchable::InstanceMethods

    attr_accessor :__selected_fields
    attr_reader :new_record

    included do
      Mongoid.register_model(self)
    end

    # Regex for matching illegal BSON keys.
    # Note that bson 4.1 has the constant BSON::String::ILLEGAL_KEY
    # that should be used instead.
    # When ruby driver 2.3.0 is released and Mongoid can be updated
    # to require >= 2.3.0, the BSON constant can be used.
    ILLEGAL_KEY = /(\A[$])|(\.)/.freeze

    # Freezes the internal attributes of the document.
    #
    # @example Freeze the document
    #   document.freeze
    #
    # @return [ Document ] The document.
    def freeze
      as_attributes.freeze and self
    end

    # Checks if the document is frozen
    #
    # @example Check if frozen
    #   document.frozen?
    #
    # @return [ true | false ] True if frozen, else false.
    def frozen?
      attributes.frozen?
    end

    # Delegates to identity in order to allow two records of the same identity
    # to work with something like:
    #
    #   [ Person.find(1), Person.find(2), Person.find(3) ] &
    #   [ Person.find(1), Person.find(4) ] # => [ Person.find(1) ]
    #
    # @example Get the hash.
    #   document.hash
    #
    # @return [ Integer ] The hash of the document's identity.
    def hash
      identity.hash
    end

    # A Document's is identified absolutely by its class and database id:
    #
    # Person.first.identity #=> [Person, BSON::ObjectId('4f775130a04745933a000003')]
    #
    # @example Get the identity
    #   document.identity
    #
    # @return [ Array ] An array containing [document.class, document._id]
    def identity
      [ self.class, _id ]
    end

    # Instantiate a new +Document+, setting the Document's attributes if
    # given. If no attributes are provided, they will be initialized with
    # an empty +Hash+.
    #
    # If a primary key is defined, the document's id will be set to that key,
    # otherwise it will be set to a fresh +BSON::ObjectId+ string.
    #
    # @example Create a new document.
    #   Person.new(:title => 'Sir')
    #
    # @param [ Hash ] attrs The attributes to set up the document with.
    #
    # @return [ Document ] A new document.
    def initialize(attrs = nil, &block)
      construct_document(attrs, execute_callbacks: Threaded.execute_callbacks?, &block)
    end

    # Return the model name of the document.
    #
    # @example Return the model name.
    #   document.model_name
    #
    # @return [ String ] The model name.
    def model_name
      self.class.model_name
    end

    # Return the key value for the document.
    #
    # @example Return the key.
    #   document.to_key
    #
    # @return [ String ] The id of the document or nil if new.
    def to_key
      (persisted? || destroyed?) ? [ _id.to_s ] : nil
    end

    # Return a hash of the entire document hierarchy from this document and
    # below. Used when the attributes are needed for everything and not just
    # the current document.
    #
    # @example Get the full hierarchy.
    #   person.as_document
    #
    # @return [ Hash ] A hash of all attributes in the hierarchy.
    def as_document
      BSON::Document.new(as_attributes)
    end

    # Calls #as_json on the document with additional, Mongoid-specific options.
    #
    # @note Rails 6 changes return value of as_json for non-primitive types
    #   such as BSON::ObjectId. In Rails <= 5, as_json returned these as
    #   instances of the class. In Rails 6, these are returned serialized to
    #   primitive types (e.g. {'$oid'=>'5bcfc40bde340b37feda98e9'}).
    #   See https://github.com/rails/rails/commit/2e5cb980a448e7f4ab00df6e9ad4c1cc456616aa
    #   for more information.
    #
    # @example Get the document as json.
    #   document.as_json(compact: true)
    #
    # @param [ Hash ] options The options.
    #
    # @option options [ true | false ] :compact (Deprecated) Whether to include fields
    #   with nil values in the json document.
    #
    # @return [ Hash ] The document as json.
    def as_json(options = nil)
      rv = super
      if options && options[:compact]
        Mongoid::Warnings.warn_as_json_compact_deprecated
        rv = rv.compact
      end
      rv
    end

    # Returns an instance of the specified class with the attributes,
    # errors, and embedded documents of the current document.
    #
    # @example Return a subclass document as a superclass instance.
    #   manager.becomes(Person)
    #
    # @raise [ ArgumentError ] If the class doesn't include Mongoid::Document
    #
    # @param [ Class ] klass The class to become.
    #
    # @return [ Document ] An instance of the specified class.
    def becomes(klass)
      unless klass.include?(Mongoid::Document)
        raise ArgumentError, 'A class which includes Mongoid::Document is expected'
      end

      became = klass.new(clone_document)
      became.set_internal_state(
        id: _id,
        changed_attributes: changed_attributes,
        errors: ActiveModel::Errors.new(became).tap { |e| e.copy!(errors) },
        new_record: new_record?,
        destroyed: destroyed?
      )

      became.changed_attributes[klass.discriminator_key] = self.class.discriminator_value
      became[klass.discriminator_key] = klass.discriminator_value

      became
    end

    # Sets the internal state of this document. Used only by #becomes to
    # help initialize a retyped document.
    #
    # @params id [Object] the value to use for the record's _id
    # @params changed_attributes [Hash] the hash to use for the changed
    #   attributes
    # @params errors [ActiveModel::Errors] the errors object to use
    # @params new_record [ true | false ] whether or not the record is
    #   unpersisted
    # @params destroyed [ true | false ] whether or not the record has been
    #   destroyed
    #
    # @api private
    def set_internal_state(id:, changed_attributes:, errors:, new_record:, destroyed:)
      self._id = id
      @changed_attributes = changed_attributes
      @errors = errors
      @new_record = new_record
      @destroyed = destroyed

      # mark embedded docs as persisted
      embedded_relations.each_pair do |name, _meta|
        without_autobuild do
          relation = __send__(name)
          Array.wrap(relation).each do |r|
            r.instance_variable_set(:@new_record, new_record)
          end
        end
      end
    end

    private

    # Does the construction of a document.
    #
    # @param [ Hash ] attrs The attributes to set up the document with.
    # @param [ true | false ] execute_callbacks Flag specifies whether callbacks
    #   should be run.
    #
    # @return [ Document ] A new document.
    #
    # @api private
    def construct_document(attrs = nil, execute_callbacks: Threaded.execute_callbacks?)
      @__parent = nil
      _building do
        @new_record = true
        @attributes ||= {}
        apply_pre_processed_defaults
        apply_default_scoping
        process_attributes(attrs) do
          yield(self) if block_given?
        end
        @attributes_before_type_cast = @attributes.merge(attributes_before_type_cast)

        if execute_callbacks
          apply_post_processed_defaults
          run_callbacks(:initialize) unless _initialize_callbacks.empty?
        else
          pending_callbacks << :apply_post_processed_defaults
          pending_callbacks << :initialize
        end
      end
      self
    end

    # Returns the logger
    #
    # @return [ Logger ] The configured logger or a default Logger instance.
    def logger
      Mongoid.logger
    end

    # Get the name of the model used in caching.
    #
    # @example Get the model key.
    #   model.model_key
    #
    # @return [ String ] The model key.
    def model_key
      @model_key ||= self.class.model_name.cache_key
    end

    # Returns a hash of the attributes.
    #
    # Note this method modifies the attributes hash that already exists on the
    # class and returns it. This means that the hash returned by this method
    # refers to the same hash as calling #attributes on the instance. See
    # MONGOID-4476 for an explanation on how this is used.
    #
    # @return [ Hash ] The attributes hash.
    def as_attributes
      return attributes if frozen?

      embedded_relations.each_pair do |name, meta|
        without_autobuild do
          relation, stored = send(name), meta.store_as
          if attributes.key?(stored) || !relation.blank?
            if relation.nil?
              attributes.delete(stored)
            else
              attributes[stored] = relation.send(:as_attributes)
            end
          end
        end
      end
      attributes
    end

    # Class-level methods for Document objects.
    module ClassMethods
      # Suppress callbacks (by default) for documents within the associated
      # block. Callbacks may still be explicitly invoked by passing
      # `execute_callbacks: true` where available.
      #
      # @params execute_callbacks [ true | false ] Whether callbacks should be
      #   suppressed or not.
      # rubocop:disable Style/OptionalBooleanParameter
      def suppress_callbacks(execute_callbacks = false)
        saved, Threaded.execute_callbacks =
          Threaded.execute_callbacks?, execute_callbacks
        yield
      ensure
        Threaded.execute_callbacks = saved
      end
      # rubocop:enable Style/OptionalBooleanParameter

      # Instantiate a new object, only when loaded from the database or when
      # the attributes have already been typecast.
      #
      # @example Create the document.
      #   Person.instantiate(:title => 'Sir', :age => 30)
      #
      # @param [ Hash ] attrs The hash of attributes to instantiate with.
      # @param [ Integer ] selected_fields The selected fields from the
      #   criteria.
      # @param [ true | false ] execute_callbacks Flag specifies whether callbacks
      #   should be run.
      #
      # @return [ Document ] A new document.
      def instantiate(attrs = nil, selected_fields = nil, &block)
        instantiate_document(
          attrs, selected_fields,
          execute_callbacks: Threaded.execute_callbacks?,
          &block
        )
      end

      # Instantiate the document.
      #
      # @param [ Hash ] attrs The hash of attributes to instantiate with.
      # @param [ Integer ] selected_fields The selected fields from the
      #   criteria.
      # @param [ true | false ] execute_callbacks Flag specifies whether callbacks
      #   should be run.
      #
      # @return [ Document ] A new document.
      #
      # @api private
      def instantiate_document(attrs = nil, selected_fields = nil, execute_callbacks: Threaded.execute_callbacks?)
        attributes = attrs&.to_h || {}

        doc = allocate
        doc.__selected_fields = selected_fields
        doc.instance_variable_set(:@attributes, attributes)
        doc.instance_variable_set(:@attributes_before_type_cast, attributes.dup)

        doc.apply_defaults if execute_callbacks

        yield(doc) if block_given?

        if execute_callbacks
          doc.run_callbacks(:find)
          doc.run_callbacks(:initialize)
        else
          doc.pending_callbacks += %i[ apply_defaults find initialize ]
        end

        doc
      end

      # Allocates and constructs a document.
      #
      # @param [ Hash ] attrs The attributes to set up the document with.
      # @param [ true | false ] execute_callbacks Flag specifies whether callbacks
      #   should be run.
      #
      # @return [ Document ] A new document.
      #
      # @api private
      def construct_document(attrs = nil, execute_callbacks: Threaded.execute_callbacks?)
        suppress_callbacks(execute_callbacks) { new(attrs) }
      end

      # Returns all types to query for when using this class as the base.
      #
      # @example Get the types.
      #   document._types
      #
      # @return [ Array<Class> ] All subclasses of the current document.
      def _types
        @_types ||= (descendants + [ self ]).uniq.map(&:discriminator_value)
      end

      # Clear the @_type cache. This is generally called when changing the discriminator
      # key/value on a class.
      #
      # @example Get the types.
      #   document._mongoid_clear_types
      #
      # @api private
      def _mongoid_clear_types
        @_types = nil
        superclass._mongoid_clear_types if hereditary?
      end

      # Set the i18n scope to overwrite ActiveModel.
      #
      # @return [ Symbol ] :mongoid
      def i18n_scope
        :mongoid
      end

      # Returns the logger
      #
      # @example Get the logger.
      #   Person.logger
      #
      # @return [ Logger ] The configured logger or a default Logger instance.
      def logger
        Mongoid.logger
      end
    end
  end
end

ActiveSupport.run_load_hooks(:mongoid, Mongoid::Document)
