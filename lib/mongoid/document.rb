# encoding: utf-8
module Mongoid #:nodoc:
  module Document
    extend ActiveSupport::Concern
    included do
      include Mongoid::Components
      attr_reader :new_record
    end

    module ClassMethods #:nodoc:

      # Instantiate a new object, only when loaded from the database or when
      # the attributes have already been typecast.
      #
      # Example:
      #
      # <tt>Person.instantiate(:title => "Sir", :age => 30)</tt>
      def instantiate(attrs = nil, allocating = false)
        attributes = attrs || {}
        if attributes["_id"] || allocating
          document = allocate
          document.instance_variable_set(:@attributes, attributes)
          document.setup_modifications
          document
        else
          new(attrs)
        end
      end

      # Returns all types to query for when using this class as the base.
      # *subclasses* is from activesupport. Note that a bug in *subclasses*
      # causes the first call to only return direct children, hence
      # the double call and unique.
      def _types
        @_type ||= [descendants + [self]].flatten.uniq.map(&:to_s)
      end
    end

    # Performs equality checking on the document ids. For more robust
    # equality checking please override this method.
    def ==(other)
      return false unless other.is_a?(Document)
      id == other.id
    end

    # Delegates to ==
    def eql?(comparison_object)
      self == (comparison_object)
    end

    # Delegates to id in order to allow two records of the same type and id to
    # work with something like:
    #   [ Person.find(1),
    #     Person.find(2),
    #     Person.find(3) ] &
    #   [ Person.find(1),
    #     Person.find(4) ] # => [ Person.find(1) ]
    def hash
      id.hash
    end

    # Return the attributes hash with indifferent access.
    def attributes
      @attributes.with_indifferent_access
    end

    # Clone the current +Document+. This will return all attributes with the
    # exception of the document's id and versions.
    def clone
      self.class.instantiate(@attributes.except("_id").except("versions").dup, true)
    end

    # Generate an id for this +Document+.
    def identify
      Identity.new(self).create
    end

    # Instantiate a new +Document+, setting the Document's attributes if
    # given. If no attributes are provided, they will be initialized with
    # an empty +Hash+.
    #
    # If a primary key is defined, the document's id will be set to that key,
    # otherwise it will be set to a fresh +BSON::ObjectID+ string.
    #
    # Options:
    #
    # attrs: The attributes +Hash+ to set up the document with.
    def initialize(attrs = nil)
      @new_record = true
      @attributes = default_attributes
      process(attrs)
      document = yield self if block_given?
      identify
      run_callbacks(:initialize) do
        document
      end
    end

    # Returns the class name plus its attributes.
    def inspect
      attrs = fields.map { |name, field| "#{name}: #{@attributes[name].inspect}" }
      if Mongoid.allow_dynamic_fields
        dynamic_keys = @attributes.keys - fields.keys - relations.keys - ["_id", "_type"]
        attrs += dynamic_keys.map { |name| "#{name}: #{@attributes[name].inspect}" }
      end
      "#<#{self.class.name} _id: #{id}, #{attrs * ', '}>"
    end

    # Return the attributes hash.
    def raw_attributes
      @attributes
    end

    # Reloads the +Document+ attributes from the database.
    def reload
      reloaded = collection.find_one(:_id => id)
      if Mongoid.raise_not_found_error
        raise Errors::DocumentNotFound.new(self.class, id) if reloaded.nil?
      end
      @attributes = {}.merge(reloaded || {})
      self.relations.keys.each { |association_name| unmemoize(association_name) }; self
    end

    # Return an array with this +Document+ only in it.
    def to_a
      [ self ]
    end
  end
end
