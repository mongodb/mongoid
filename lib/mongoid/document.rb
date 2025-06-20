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
require 'mongoid/model_resolver'

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
      Mongoid::ModelResolver.register(self)
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
      construct_document(attrs, &block)
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
      mongoid_document_check!(klass)

      became = klass.new(clone_document)
      became.internal_state = internal_state

      became
    end

    # Sets the internal state of this document. Used only by #becomes to
    # help initialize a retyped document.
    #
    # @param [ Hash ] state The map of internal state values.
    #
    # @api private
    def internal_state=(state)
      self._id = state[:id]
      @changed_attributes = state[:changed_attributes]
      @errors = ActiveModel::Errors.new(self).tap { |e| e.copy!(state[:errors]) }
      @new_record = state[:new_record]
      @destroyed = state[:destroyed]

      update_discriminator(state[:discriminator_key_was])

      mark_persisted_state_for_embedded_documents(state[:new_record])
    end

    # Handles the setup and execution of callbacks, if callbacks are to
    # be executed; otherwise, adds the appropriate callbacks to the pending
    # callbacks list.
    #
    # @param execute_callbacks [ true | false ] Whether callbacks should be
    #   executed or not.
    #
    # @api private
    def _handle_callbacks_after_instantiation(execute_callbacks)
      if execute_callbacks
        apply_defaults
        yield self if block_given?
        run_callbacks(:find) unless _find_callbacks.empty?
        run_callbacks(:initialize) unless _initialize_callbacks.empty?
      else
        yield self if block_given?
        self.pending_callbacks += %i[ apply_defaults find initialize ]
      end
    end

    private

    # Does the construction of a document.
    #
    # @param [ Hash ] attrs The attributes to set up the document with.
    # @param [ Hash ] options The options to use.
    #
    # @option options [ true | false ] :execute_callbacks Flag specifies
    #   whether callbacks should be run.
    #
    # @return [ Document ] A new document.
    #
    # @note A Ruby 2.x bug prevents the options hash from being keyword
    #   arguments. Once we drop support for Ruby 2.x, we can reimplement
    #   the options hash as keyword arguments.
    #   See https://bugs.ruby-lang.org/issues/15753
    #
    # @api private
    def construct_document(attrs = nil, options = {})
      execute_callbacks = options.fetch(:execute_callbacks, Threaded.execute_callbacks?)

      self._parent = nil
      _building do
        prepare_to_process_attributes

        process_attributes(attrs) do
          yield(self) if block_given?
        end
        @attributes_before_type_cast = @attributes.merge(attributes_before_type_cast)

        resolve_post_construction_callbacks(execute_callbacks)
      end
      self
    end

    # Initializes the object state prior to attribute processing; this is
    # called only from #construct_document.
    def prepare_to_process_attributes
      @new_record = true
      @attributes ||= {}
      apply_pre_processed_defaults
      apply_default_scoping
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
          add_attributes_for_relation(name, meta)
        end
      end

      attributes
    end

    # Adds the attributes for the given relation to the document's attributes.
    #
    # @param name [ String | Symbol ] the name of the relation to add
    # @param meta [ Mongoid::Assocation::Relatable ] the relation object
    def add_attributes_for_relation(name, meta)
      relation, stored = send(name), meta.store_as
      return unless attributes.key?(stored) || !relation.blank?

      if relation.nil?
        attributes.delete(stored)
      else
        attributes[stored] = relation.send(:as_attributes)
      end
    end

    # Checks that the given argument is an instance of `Mongoid::Document`.
    #
    # @param klass [ Class ] The class to test.
    #
    # @raise [ ArgumentError ] if the class does not include
    #   Mongoid::Document.
    def mongoid_document_check!(klass)
      return if klass.include?(Mongoid::Document)

      raise ArgumentError, 'A class which includes Mongoid::Document is expected'
    end

    # Constructs a hash representing the internal state of this object,
    # suitable for passing to #internal_state=.
    #
    # @return [ Hash ] the map of internal state values
    def internal_state
      {
        id: _id,
        changed_attributes: changed_attributes,
        errors: errors,
        new_record: new_record?,
        destroyed: destroyed?,
        discriminator_key_was: self.class.discriminator_value
      }
    end

    # Updates the value of the discriminator_key for this object, setting its
    # previous value to `key_was`.
    #
    # @param key_was [ String ] the previous value of the discriminator key.
    def update_discriminator(key_was)
      changed_attributes[self.class.discriminator_key] = key_was
      self[self.class.discriminator_key] = self.class.discriminator_value
    end

    # Marks all embedded documents with the given "new_record" state.
    #
    # @param [ true | false ] new_record  whether or not the embedded records
    #   should be flagged as new records or not.
    def mark_persisted_state_for_embedded_documents(new_record)
      embedded_relations.each_pair do |name, _meta|
        without_autobuild do
          relation = __send__(name)
          Array.wrap(relation).each do |r|
            r.instance_variable_set(:@new_record, new_record)
          end
        end
      end
    end

    # Either executes or enqueues the post-construction callbacks.
    #
    # @param [ true | false ] execute_callbacks whether the callbacks
    #   should be executed (true) or enqueued (false)
    def resolve_post_construction_callbacks(execute_callbacks)
      if execute_callbacks
        apply_post_processed_defaults
        run_callbacks(:initialize) unless _initialize_callbacks.empty?
      else
        pending_callbacks << :apply_post_processed_defaults
        pending_callbacks << :initialize
      end
    end

    # Class-level methods for Document objects.
    module ClassMethods
      # Indicate whether callbacks should be invoked by default or not,
      # within the block. Callbacks may always be explicitly invoked by passing
      # `execute_callbacks: true` where available.
      #
      # @param [ true | false ] execute_callbacks Whether callbacks should be
      #   suppressed or not.
      def with_callbacks(execute_callbacks)
        saved, Threaded.execute_callbacks =
          Threaded.execute_callbacks?, execute_callbacks
        yield
      ensure
        Threaded.execute_callbacks = saved
      end

      # Instantiate a new object, only when loaded from the database or when
      # the attributes have already been typecast.
      #
      # @example Create the document.
      #   Person.instantiate(:title => 'Sir', :age => 30)
      #
      # @param [ Hash ] attrs The hash of attributes to instantiate with.
      # @param [ Integer ] selected_fields The selected fields from the
      #   criteria.
      #
      # @return [ Document ] A new document.
      def instantiate(attrs = nil, selected_fields = nil, &block)
        instantiate_document(attrs, selected_fields, &block)
      end

      # Instantiate the document.
      #
      # @param [ Hash ] attrs The hash of attributes to instantiate with.
      # @param [ Integer ] selected_fields The selected fields from the
      #   criteria.
      # @param [ Hash ] options The options to use.
      #
      # @option options [ true | false ] :execute_callbacks Flag specifies
      #   whether callbacks should be run.
      #
      # @yield [ Mongoid::Document ] If a block is given, yields the newly
      #   instantiated document to it.
      #
      # @return [ Document ] A new document.
      #
      # @note A Ruby 2.x bug prevents the options hash from being keyword
      #   arguments. Once we drop support for Ruby 2.x, we can reimplement
      #   the options hash as keyword arguments.
      #
      # @api private
      def instantiate_document(attrs = nil, selected_fields = nil, options = {}, &block)
        execute_callbacks = options.fetch(:execute_callbacks, Threaded.execute_callbacks?)
        attributes = attrs&.to_h || {}

        doc = allocate
        doc.__selected_fields = selected_fields
        doc.instance_variable_set(:@attributes, attributes)
        doc.instance_variable_set(:@attributes_before_type_cast, attributes.dup)

        doc._handle_callbacks_after_instantiation(execute_callbacks, &block)

        doc.remember_storage_options!
        doc
      end

      # Allocates and constructs a document.
      #
      # @param [ Hash ] attrs The attributes to set up the document with.
      # @param [ Hash ] options The options to use.
      #
      # @option options [ true | false ] :execute_callbacks Flag specifies
      #   whether callbacks should be run.
      #
      # @note A Ruby 2.x bug prevents the options hash from being keyword
      #   arguments. Once we drop support for Ruby 2.x, we can reimplement
      #   the options hash as keyword arguments.
      #   See https://bugs.ruby-lang.org/issues/15753
      #
      # @return [ Document ] A new document.
      #
      # @api private
      def construct_document(attrs = nil, options = {})
        execute_callbacks = options.fetch(:execute_callbacks, Threaded.execute_callbacks?)
        with_callbacks(execute_callbacks) { new(attrs) }
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
