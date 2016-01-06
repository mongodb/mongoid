# encoding: utf-8
require "mongoid/positional"
require "mongoid/evolvable"
require "mongoid/extensions"
require "mongoid/errors"
require "mongoid/threaded"
require "mongoid/relations"
require "mongoid/atomic"
require "mongoid/attributes"
require "mongoid/contextual"
require "mongoid/copyable"
require "mongoid/equality"
require "mongoid/criteria"
require "mongoid/factory"
require "mongoid/fields"
require "mongoid/timestamps"
require "mongoid/composable"

module Mongoid

  # This is the base module for all domain objects that need to be persisted to
  # the database as documents.
  module Document
    extend ActiveSupport::Concern
    include Composable

    attr_accessor :__selected_fields
    attr_reader :new_record

    included do
      Mongoid.register_model(self)
    end

    # Freezes the internal attributes of the document.
    #
    # @example Freeze the document
    #   document.freeze
    #
    # @return [ Document ] The document.
    #
    # @since 2.0.0
    def freeze
      as_document.freeze and self
    end

    # Checks if the document is frozen
    #
    # @example Check if frozen
    #   document.frozen?
    #
    # @return [ true, false ] True if frozen, else false.
    #
    # @since 2.0.0
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
    #
    # @since 1.0.0
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
    #
    # @since 3.0.0
    def identity
      [ self.class, self._id ]
    end

    # Instantiate a new +Document+, setting the Document's attributes if
    # given. If no attributes are provided, they will be initialized with
    # an empty +Hash+.
    #
    # If a primary key is defined, the document's id will be set to that key,
    # otherwise it will be set to a fresh +BSON::ObjectId+ string.
    #
    # @example Create a new document.
    #   Person.new(:title => "Sir")
    #
    # @param [ Hash ] attrs The attributes to set up the document with.
    #
    # @return [ Document ] A new document.
    #
    # @since 1.0.0
    def initialize(attrs = nil)
      _building do
        @new_record = true
        @attributes ||= {}
        with(self.class.persistence_options)
        apply_pre_processed_defaults
        apply_default_scoping
        process_attributes(attrs) do
          yield(self) if block_given?
        end
        apply_post_processed_defaults
        # @todo: #2586: Need to have access to parent document in these
        #   callbacks.
        run_callbacks(:initialize) unless _initialize_callbacks.empty?
      end
    end

    # Return the model name of the document.
    #
    # @example Return the model name.
    #   document.model_name
    #
    # @return [ String ] The model name.
    #
    # @since 3.0.16
    def model_name
      self.class.model_name
    end

    # Return the key value for the document.
    #
    # @example Return the key.
    #   document.to_key
    #
    # @return [ String ] The id of the document or nil if new.
    #
    # @since 2.4.0
    def to_key
      (persisted? || destroyed?) ? [ id.to_s ] : nil
    end

    # Return an array with this +Document+ only in it.
    #
    # @example Return the document in an array.
    #   document.to_a
    #
    # @return [ Array<Document> ] An array with the document as its only item.
    #
    # @since 1.0.0
    def to_a
      [ self ]
    end

    # Return a hash of the entire document hierarchy from this document and
    # below. Used when the attributes are needed for everything and not just
    # the current document.
    #
    # @example Get the full hierarchy.
    #   person.as_document
    #
    # @return [ Hash ] A hash of all attributes in the hierarchy.
    #
    # @since 1.0.0
    def as_document
      return attributes if frozen?
      embedded_relations.each_pair do |name, meta|
        without_autobuild do
          relation, stored = send(name), meta.store_as
          if attributes.key?(stored) || !relation.blank?
            if relation
              attributes[stored] = relation.as_document
            else
              attributes.delete(stored)
            end
          end
        end
      end
      attributes
    end

    # Calls #as_json on the document with additional, Mongoid-specific options.
    #
    # @example Get the document as json.
    #   document.as_json(compact: true)
    #
    # @param [ Hash ] options The options.
    #
    # @option options [ true, false ] :compact Whether to include fields with
    #   nil values in the json document.
    #
    # @return [ Hash ] The document as json.
    #
    # @since 5.1.0
    def as_json(options = nil)
      if options && (options[:compact] == true)
        super(options).reject! { |k,v| v.nil? }
      else
        super(options)
      end
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
    #
    # @since 2.0.0
    def becomes(klass)
      unless klass.include?(Mongoid::Document)
        raise ArgumentError, "A class which includes Mongoid::Document is expected"
      end

      became = klass.new(clone_document)
      became._id = _id
      became.instance_variable_set(:@changed_attributes, changed_attributes)
      became.instance_variable_set(:@errors, ActiveModel::Errors.new(became))
      became.errors.instance_variable_set(:@messages, errors.instance_variable_get(:@messages))
      became.instance_variable_set(:@new_record, new_record?)
      became.instance_variable_set(:@destroyed, destroyed?)
      became.changed_attributes["_type"] = self.class.to_s
      became._type = klass.to_s

      # mark embedded docs as persisted
      embedded_relations.each_pair do |name, meta|
        without_autobuild do
          relation = became.__send__(name)
          Array.wrap(relation).each do |r|
            r.instance_variable_set(:@new_record, new_record?)
          end
        end
      end

      became
    end

    # Print out the cache key. This will append different values on the
    # plural model name.
    #
    # If new_record?     - will append /new
    # If not             - will append /id-updated_at.to_s(:nsec)
    # Without updated_at - will append /id
    #
    # This is usually called insode a cache() block
    #
    # @example Returns the cache key
    #   document.cache_key
    #
    # @return [ String ] the string with or without updated_at
    #
    # @since 2.4.0
    def cache_key
      return "#{model_key}/new" if new_record?
      return "#{model_key}/#{id}-#{updated_at.utc.to_s(:nsec)}" if do_or_do_not(:updated_at)
      "#{model_key}/#{id}"
    end

    private

    # Returns the logger
    #
    # @return [ Logger ] The configured logger or a default Logger instance.
    #
    # @since 2.2.0
    def logger
      Mongoid.logger
    end

    # Get the name of the model used in caching.
    #
    # @example Get the model key.
    #   model.model_key
    #
    # @return [ String ] The model key.
    #
    # @since 2.4.0
    def model_key
      @model_cache_key ||= self.class.model_name.cache_key
    end

    # Implement this for calls to flatten on array.
    #
    # @example Get the document as an array.
    #   document.to_ary
    #
    # @return [ nil ] Always nil.
    #
    # @since 2.1.0
    def to_ary
      nil
    end

    module ClassMethods

      # Performs class equality checking.
      #
      # @example Compare the classes.
      #   document === other
      #
      # @param [ Document, Object ] other The other object to compare with.
      #
      # @return [ true, false ] True if the classes are equal, false if not.
      #
      # @since 2.0.0.rc.4
      def ===(other)
        other.class == Class ? self <= other : other.is_a?(self)
      end

      # Instantiate a new object, only when loaded from the database or when
      # the attributes have already been typecast.
      #
      # @example Create the document.
      #   Person.instantiate(:title => "Sir", :age => 30)
      #
      # @param [ Hash ] attrs The hash of attributes to instantiate with.
      # @param [ Integer ] selected_fields The selected fields from the
      #   criteria.
      #
      # @return [ Document ] A new document.
      #
      # @since 1.0.0
      def instantiate(attrs = nil, selected_fields = nil)
        attributes = attrs || {}
        doc = allocate
        doc.__selected_fields = selected_fields
        doc.instance_variable_set(:@attributes, attributes)
        doc.apply_defaults
        yield(doc) if block_given?
        doc.run_callbacks(:find) unless doc._find_callbacks.empty?
        doc.run_callbacks(:initialize) unless doc._initialize_callbacks.empty?
        doc
      end

      # Returns all types to query for when using this class as the base.
      #
      # @example Get the types.
      #   document._types
      #
      # @return [ Array<Class> ] All subclasses of the current document.
      #
      # @since 1.0.0
      def _types
        @_type ||= (descendants + [ self ]).uniq.map(&:to_s)
      end

      # Set the i18n scope to overwrite ActiveModel.
      #
      # @return [ Symbol ] :mongoid
      #
      # @since 2.0.0
      def i18n_scope
        :mongoid
      end

      # Returns the logger
      #
      # @example Get the logger.
      #   Person.logger
      #
      # @return [ Logger ] The configured logger or a default Logger instance.
      #
      # @since 2.2.0
      def logger
        Mongoid.logger
      end
    end
  end
end

ActiveSupport.run_load_hooks(:mongoid, Mongoid::Document)
