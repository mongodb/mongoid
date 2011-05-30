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

    # Freezes the internal attributes of the document.
    #
    # @example Freeze the document
    #   document.freeze
    #
    # @return [ Document ] The document.
    #
    # @since 2.0.0
    def freeze
      attributes.freeze
      self
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
      raw_attributes.frozen?
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
      raw_attributes["_id"].hash
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
      @attributes = apply_default_attributes
      process(attrs) do |document|
        yield self if block_given?
        identify
      end
      run_callbacks(:initialize) { self }
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
      apply_default_attributes
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
      attribs = attributes
      attribs.tap do |attrs|
        relations.select { |name, meta| meta.embedded? }.each do |name, meta|
          relation = send(name, false, :continue => false)
          attrs[name] = relation.as_document unless relation.blank?
        end
      end
    end

    # Returns an instance of the specified class with the attributes
    # and errors of the current document.
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
      became = klass.new
      became.instance_variable_set('@attributes', @attributes)
      became.instance_variable_set('@errors', @errors)
      became.instance_variable_set('@new_record', new_record?)
      became.instance_variable_set('@destroyed', destroyed?)
      became
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
        allocate.tap do |doc|
          doc.instance_variable_set(:@attributes, attributes)
          doc.send(:apply_default_attributes)
          doc.setup_modifications
          doc.run_callbacks(:initialize) { doc }
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
