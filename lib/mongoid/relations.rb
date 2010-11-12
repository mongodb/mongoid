# encoding: utf-8
require "mongoid/relations/accessors"
require "mongoid/relations/cyclic"
require "mongoid/relations/proxy"
require "mongoid/relations/bindings"
require "mongoid/relations/builders"
require "mongoid/relations/many_to_one"
require "mongoid/relations/one_to_one"
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
    include Cyclic
    include Builders
    include Macros
    include Reflections

    included do
      attr_accessor :metadata
    end

    # Determine if the document itself is embedded in another document via the
    # proper channels. (If it has a parent document.)
    #
    # Example:
    #
    # <tt>address.embedded?</tt>
    #
    # Returns:
    #
    # True if the document has a parent document.
    def embedded?
      _parent.present?
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
  end
end
