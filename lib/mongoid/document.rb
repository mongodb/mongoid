# encoding: utf-8
module Mongoid

  # This is the base module for all domain objects that need to be persisted to
  # the database as documents.
  module Document
    extend ActiveSupport::Concern
    include Mongoid::Components

    attr_accessor :criteria_instance_id
    attr_reader :new_record

    # Default comparison is via the string version of the id.
    #
    # @example Compare two documents.
    #   person <=> other_person
    #
    # @param [ Document ] other The document to compare with.
    #
    # @return [ Integer ] -1, 0, 1.
    #
    # @since 1.0.0
    def <=>(other)
      attributes["_id"].to_s <=> other.attributes["_id"].to_s
    end

    # Performs equality checking on the document ids. For more robust
    # equality checking please override this method.
    #
    # @example Compare for equality.
    #   document == other
    #
    # @param [ Document, Object ] other The other object to compare with.
    #
    # @return [ true, false ] True if the ids are equal, false if not.
    #
    # @since 1.0.0
    def ==(other)
      self.class == other.class &&
        attributes["_id"] == other.attributes["_id"]
    end

    # Performs class equality checking.
    #
    # @example Compare the classes.
    #   document === other
    #
    # @param [ Document, Object ] other The other object to compare with.
    #
    # @return [ true, false ] True if the classes are equal, false if not.
    #
    # @since 1.0.0
    def ===(other)
      other.class == Class ? self.class === other : self == other
    end

    # Delegates to ==. Used when needing checks in hashes.
    #
    # @example Perform equality checking.
    #   document.eql?(other)
    #
    # @param [ Document, Object ] other The object to check against.
    #
    # @return [ true, false ] True if equal, false if not.
    #
    # @since 1.0.0
    def eql?(other)
      self == (other)
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

    # A Document's is identified absolutely by it's class and database id:
    #
    # Person.first.identity #=> [Person, Moped::BSON::ObjectId('4f775130a04745933a000003')]
    #
    # @example Get the identity
    #   document.identity
    #
    # @return [ Array ] An array containing [document.class, document.id]
    #
    # @since 3.0.0
    def identity
      [ self.class, self.id ]
    end

    # Instantiate a new +Document+, setting the Document's attributes if
    # given. If no attributes are provided, they will be initialized with
    # an empty +Hash+.
    #
    # If a primary key is defined, the document's id will be set to that key,
    # otherwise it will be set to a fresh +Moped::BSON::ObjectId+ string.
    #
    # @example Create a new document.
    #   Person.new(:title => "Sir")
    #
    # @param [ Hash ] attrs The attributes to set up the document with.
    # @param [ Hash ] options A mass-assignment protection options. Supports
    #   :as and :without_protection
    #
    # @return [ Document ] A new document.
    #
    # @since 1.0.0
    def initialize(attrs = nil, options = nil)
      _building do
        @new_record = true
        @attributes ||= {}
        @attributes_before_type_cast ||= {}
        options ||= {}
        apply_pre_processed_defaults
        process_attributes(attrs, options[:as] || :default, !options[:without_protection]) do
          yield(self) if block_given?
        end
        apply_post_processed_defaults
        run_callbacks(:initialize) unless _initialize_callbacks.empty?
      end
    end

    # Return the key value for the document.
    #
    # @example Return the key.
    #   document.to_key
    #
    # @return [ Object ] The id of the document or nil if new.
    #
    # @since 2.4.0
    def to_key
      (persisted? || destroyed?) ? [ id ] : nil
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
          relation = send(name)
          attributes[meta.store_as] = relation.as_document unless relation.blank?
        end
      end
      attributes
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
      became = klass.new(as_document.__deep_copy__)
      became.instance_variable_set(:@changed_attributes, changed_attributes)
      became.instance_variable_set(:@errors, errors)
      became.instance_variable_set(:@new_record, new_record?)
      became.instance_variable_set(:@destroyed, destroyed?)
      became._type = klass.to_s
      became
    end

    # Print out the cache key. This will append different values on the
    # plural model name.
    #
    # If new_record?     - will append /new
    # If not             - will append /id-updated_at.to_s(:number)
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
      return "#{model_key}/#{id}-#{updated_at.utc.to_s(:number)}" if updated_at
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
      @model_cache_key ||= "#{self.class.model_name.cache_key}"
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
      # @param [ Integer ] criteria_instance_id The criteria id that
      #   instantiated the document.
      #
      # @return [ Document ] A new document.
      #
      # @since 1.0.0
      def instantiate(attrs = nil, criteria_instance_id = nil)
        attributes = attrs || {}
        doc = allocate
        doc.criteria_instance_id = criteria_instance_id
        doc.instance_variable_set(:@attributes, attributes)
        doc.instance_variable_set(:@attributes_before_type_cast, {})
        doc.apply_defaults
        IdentityMap.set(doc) unless _loading_revision?
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
        @_type ||= (descendants + [ self ]).uniq.map { |t| t.to_s }
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
