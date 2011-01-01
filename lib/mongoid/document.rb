# encoding: utf-8
module Mongoid #:nodoc:
  module Document
    extend ActiveSupport::Concern

    included do
      include Mongoid::Components
      attr_accessor :new_record
    end

    # Default comparison is via the string version of the id.
    #
    # Example:
    #
    # <tt>person <=> person</tt>
    #
    # Options:
    #
    # other: The document to compare with.
    #
    # Returns -1, 0, 1.
    def <=>(other)
      id.to_s <=> other.id.to_s
    end

    # Performs equality checking on the document ids. For more robust
    # equality checking please override this method.
    #
    # Example:
    #
    # <tt>document == other</tt>
    #
    # Options:
    #
    # other: The other object to compare with
    #
    # Returns:
    #
    # true if the ids are equal, false if not.
    def ==(other)
      return false unless other.is_a?(Document)
      id == other.id || equal?(other)
    end

    # Performs class equality checking.
    #
    # Example:
    #
    # <tt>document === other</tt>
    #
    # Options:
    #
    # other: The other object to compare with
    #
    # Returns:
    #
    # true if the classes are equal, false if not.
    def ===(other)
      self.class == other.class
    end

    # Delegates to ==. Used when needing checks in hashes.
    #
    # Example:
    #
    # <tt>document.eql?(other)</tt>
    #
    # Options:
    #
    # other: The object to check against.
    #
    # Returns:
    #
    # true if equal, false if not.
    def eql?(other)
      self == (other)
    end

    # Delegates to id in order to allow two records of the same type and id to
    # work with something like:
    #
    #   [ Person.find(1), Person.find(2), Person.find(3) ] &
    #   [ Person.find(1), Person.find(4) ] # => [ Person.find(1) ]
    #
    # Example:
    #
    # <tt>document.hash</tt>
    #
    # Returns:
    #
    # The hash of the document's id.
    def hash
      id.hash
    end

    # Return the attributes hash with indifferent access. Used mostly for
    # convenience - use +Document#raw_attributes+ where you dont care if the
    # keys are all strings.
    #
    # Example:
    #
    # <tt>person.attributes</tt>
    #
    # Returns:
    #
    # The attributes hash with indifferent access.
    def attributes
      @attributes.with_indifferent_access
    end

    # Generate an id for this +Document+.
    #
    # Example:
    #
    # <tt>person.identify</tt>
    #
    # Returns:
    #
    # A newly created id based on the strategy for creation.
    def identify
      Identity.new(self).create
    end

    # Instantiate a new +Document+, setting the Document's attributes if
    # given. If no attributes are provided, they will be initialized with
    # an empty +Hash+.
    #
    # If a primary key is defined, the document's id will be set to that key,
    # otherwise it will be set to a fresh +BSON::ObjectId+ string.
    #
    # Example:
    #
    # <tt>Person.new(:title => "Sir")</tt>
    #
    # Options:
    #
    # attrs: The attributes +Hash+ to set up the document with.
    #
    # Returns:
    #
    # A new document.
    def initialize(attrs = nil)
      @new_record = true
      @attributes = default_attributes
      process(attrs)
      reset_modifications
      document = yield self if block_given?
      identify
      run_callbacks(:initialize) { document }
    end

    # Return the attributes hash.
    #
    # Example:
    #
    # <tt>person.raw_attributes</tt>
    #
    # Returns:
    #
    # This document's attributes.
    def raw_attributes
      @attributes
    end

    # Reloads the +Document+ attributes from the database. If the document has
    # not been saved then an error will get raised if the configuration option
    # was set.
    #
    # Example:
    #
    # <tt>person.reload</tt>
    #
    # Returns:
    #
    # The document, reloaded.
    def reload
      reloaded = collection.find_one(:_id => id)
      if Mongoid.raise_not_found_error
        raise Errors::DocumentNotFound.new(self.class, id) if reloaded.nil?
      end
      @attributes = {}.merge(reloaded || {})
      tap do
        relations.keys.each do |name|
          if relation_exists?(name)
            remove_instance_variable("@#{name}")
          end
        end
      end
    end

    # TODO: Need to reindex at this point for embeds many.
    #
    # Remove a child document from this parent. If an embeds one then set to
    # nil, otherwise remove from the embeds many.
    #
    # This is called from the +RemoveEmbedded+ persistence command.
    #
    # Example:
    #
    # <tt>document.remove_child(child)</tt>
    #
    # Options:
    #
    # child: The child (embedded) document to remove.
    def remove_child(child)
      name = child.metadata.name
      if child.embedded_one?
        remove_instance_variable("@#{name}") if instance_variable_defined?("@#{name}")
      else
        send(name).delete(child)
      end
    end

    # Return an array with this +Document+ only in it.
    #
    # Example:
    #
    # <tt>document.to_a</tt>
    #
    # Returns:
    #
    # An array with the document as its only item.
    def to_a
      [ self ]
    end

    # Return a hash of the entire document hierarchy from this document and
    # below. Used when the attributes are needed for everything and not just
    # the current document.
    #
    # Example:
    #
    # <tt>person.to_hash</tt>
    #
    # Returns:
    #
    # A hash of all attributes in the hierarchy.
    def to_hash
      attributes = @attributes
      attributes.tap do |attrs|
        relations.select { |name, meta| meta.embedded? }.each do |name, meta|
          relation = send(name)
          attrs[name] = relation.to_hash unless relation.blank?
        end
      end
    end

    module ClassMethods #:nodoc:

      # Instantiate a new object, only when loaded from the database or when
      # the attributes have already been typecast.
      #
      # Example:
      #
      # <tt>Person.instantiate(:title => "Sir", :age => 30)</tt>
      #
      # Options:
      #
      # attrs: The hash of attributes to instantiate with.
      # allocating: Set to true if cloning.
      #
      # Returns:
      #
      # A new document.
      def instantiate(attrs = nil)
        attributes = attrs || {}
        if attributes["_id"]
          allocate.tap do |doc|
            doc.instance_variable_set(:@attributes, attributes)
            doc.setup_modifications
          end
        else
          new(attrs)
        end
      end

      # Returns all types to query for when using this class as the base.
      #
      # Example:
      #
      # <tt>document._types</tt>
      #
      # Returns:
      #
      # All subclasses of the current document.
      def _types
        @_type ||= [descendants + [self]].flatten.uniq.map(&:to_s)
      end
    end
  end
end
