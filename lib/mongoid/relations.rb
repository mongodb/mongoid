# encoding: utf-8
require "mongoid/relations/accessors"
require "mongoid/relations/proxy"
require "mongoid/relations/bindings"
require "mongoid/relations/builders"
require "mongoid/relations/embedded/in"
require "mongoid/relations/embedded/many"
require "mongoid/relations/embedded/one"
require "mongoid/relations/referenced/in"
require "mongoid/relations/referenced/in_from_array"
require "mongoid/relations/referenced/many"
require "mongoid/relations/referenced/many_as_array"
require "mongoid/relations/referenced/many_to_many"
require "mongoid/relations/referenced/one"
require "mongoid/relations/reflections"
require "mongoid/relations/metadata"
require "mongoid/relations/macros"

module Mongoid # :nodoc:
  module Relations #:nodoc:
    extend ActiveSupport::Concern
    include Accessors
    include Builders
    include Macros
    include Reflections

    included do
      cattr_accessor :embedded
      attr_accessor :metadata
      self.embedded = false

      # Convenience methods for the instance to know about attributes that
      # are located at the class level.
      delegate \
        :embedded,
        :embedded?, :to => "self.class"
    end

    # Determine if the document is part of an embeds_one relation.
    #
    # Example:
    #
    # <tt>address.embedded_many?</tt>
    #
    # Returns:
    #
    # True if in an embeds many.
    def embedded_many?
      metadata && metadata.macro == :embeds_many
    end

    # Determine if the document is part of an embeds_one relation.
    #
    # Example:
    #
    # <tt>address.embedded_one?</tt>
    #
    # Returns:
    #
    # True if in an embeds one.
    def embedded_one?
      metadata && metadata.macro == :embeds_one
    end

    # Determine if the document is part of an references_one relation.
    #
    # Example:
    #
    # <tt>address.referenced_many?</tt>
    #
    # Returns:
    #
    # True if in a references many.
    def referenced_many?
      metadata && metadata.macro == :references_many
    end

    # Determine if the document is part of an references_one relation.
    #
    # Example:
    #
    # <tt>address.referenced_one?</tt>
    #
    # Returns:
    #
    # True if in a references one.
    def referenced_one?
      metadata && metadata.macro == :references_one
    end

    module ClassMethods #:nodoc:

      # Specifies whether or not the class is an embedded document.
      #
      # Example:
      #
      # <tt>Address.embedded?</tt>
      #
      # Returns:
      #
      # true if embedded, false if not.
      def embedded?
        !!embedded
      end
    end
  end
end
