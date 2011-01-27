# encoding: utf-8
module Mongoid #:nodoc:

  # This is the base module for all domain objects that need to be persisted to
  # the database as documents.
  module Document
    extend ActiveSupport::Concern
    include Mongoid::Components
    include Mongoid::MultiDatabase

    included do
      attr_reader :new_record
    end

    # Default comparison is via the string version of the id.
    #
    # @example Compare two documents.
    #   person <=> other_person
    #
    # @param [ Document ] other The document to compare with.
    #
    # @return [ Integer ] -1, 0, 1.
    def <=>(other)
      id.to_s <=> other.id.to_s
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
    def ==(other)
      return false unless other.is_a?(Document)
      id == other.id || equal?(other)
    end

    # Performs class equality checking.
    #
    # @example Compare the classes.
    #   document === other
    #
    # @param [ Document, Object ] other The other object to compare with.
    #
    # @return [ true, false ] True if the classes are equal, false if not.
    def ===(other)
      self.class == other.class
    end

    # Delegates to ==. Used when needing checks in hashes.
    #
    # @example Perform equality checking.
    #   document.eql?(other)
    #
    # @param [ Document, Object ] other The object to check against.
    #
    # @return [ true, false ] True if equal, false if not.
    def eql?(other)
      self == (other)
    end

    # Delegates to id in order to allow two records of the same type and id to
    # work with something like:
    #
    #   [ Person.find(1), Person.find(2), Person.find(3) ] &
    #   [ Person.find(1), Person.find(4) ] # => [ Person.find(1) ]
    #
    # @example Get the hash.
    #   document.hash
    #
    # @return [ Integer ] The hash of the document's id.
    def hash
      id.hash
    end

    # Return the attributes hash with indifferent access. Used mostly for
    # convenience - use +Document#raw_attributes+ where you dont care if the
    # keys are all strings.
    #
    # @example Get the attributes.
    #   person.attributes
    #
    # @return [ HashWithIndifferentAccess ] The attributes.
    def attributes
      @attributes.with_indifferent_access
    end

    # Generate an id for this +Document+.
    #
    # @example Create the id.
    #   person.identify
    #
    # @return [ BSON::ObjectId, String ] A newly created id.
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
    # @example Create a new document.
    #   Person.new(:title => "Sir")
    #
    # @param [ Hash ] attrs The attributes to set up the document with.
    #
    # @return [ Document ] A new document.
    def initialize(attrs = nil)
      @new_record = true
      @attributes = default_attributes
      process(attrs) do |document|
        yield self if block_given?
        identify
      end
      run_callbacks(:initialize) { self }
    end

    # Return the attributes hash.
    #
    # @example Get the untouched attributes.
    #   person.raw_attributes
    #
    # @return [ Hash ] This document's attributes.
    def raw_attributes
      @attributes
    end

    # Reloads the +Document+ attributes from the database. If the document has
    # not been saved then an error will get raised if the configuration option
    # was set.
    #
    # @example Reload the document.
    #   person.reload
    #
    # @raise [ Errors::DocumentNotFound ] If the document was deleted.
    #
    # @return [ Document ] The document, reloaded.
    def reload
      reloaded = collection.find_one(:_id => id)
      if Mongoid.raise_not_found_error
        raise Errors::DocumentNotFound.new(self.class, id) if reloaded.nil?
      end
      @attributes = {}.merge(reloaded || {})
      reset_modifications
      tap do
        relations.keys.each do |name|
          if instance_variable_defined?("@#{name}")
            remove_instance_variable("@#{name}")
          end
        end
      end
    end

    # Remove a child document from this parent. If an embeds one then set to
    # nil, otherwise remove from the embeds many.
    #
    # This is called from the +RemoveEmbedded+ persistence command.
    #
    # @example Remove the child.
    #   document.remove_child(child)
    #
    # @param [ Document ] child The child (embedded) document to remove.
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
    # @example Return the document in an array.
    #   document.to_a
    #
    # @return [ Array<Document> ] An array with the document as its only item.
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
    def as_document
      attributes = @attributes
      attributes.tap do |attrs|
        relations.select { |name, meta| meta.embedded? }.each do |name, meta|
          relation = send(name, false, :continue => false)
          attrs[name] = relation.as_document unless relation.blank?
        end
      end
    end

    module ClassMethods #:nodoc:

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
        self == (other.is_a?(Class) ? other : other.class)
      end

      # Instantiate a new object, only when loaded from the database or when
      # the attributes have already been typecast.
      #
      # @example Create the document.
      #   Person.instantiate(:title => "Sir", :age => 30)
      #
      # @param [ Hash ] attrs The hash of attributes to instantiate with.
      #
      # @return [ Document ] A new document.
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
      # @example Get the types.
      #   document._types
      #
      # @return [ Array<Class> ] All subclasses of the current document.
      def _types
        @_type ||= [descendants + [self]].flatten.uniq.map(&:to_s)
      end

      # Set the i18n scope to overwrite ActiveModel.
      def i18n_scope
        :mongoid
      end
    end
  end
end
