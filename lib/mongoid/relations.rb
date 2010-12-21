# encoding: utf-8
require "mongoid/relations/accessors"
require "mongoid/relations/cascading"
require "mongoid/relations/cyclic"
require "mongoid/relations/proxy"
require "mongoid/relations/bindings"
require "mongoid/relations/builders"
require "mongoid/relations/many"
require "mongoid/relations/one"
require "mongoid/relations/polymorphic"
require "mongoid/relations/embedded/in"
require "mongoid/relations/embedded/many"
require "mongoid/relations/embedded/one"
require "mongoid/relations/referenced/in"
require "mongoid/relations/referenced/many"
require "mongoid/relations/referenced/many_to_many"
require "mongoid/relations/referenced/one"
require "mongoid/relations/reflections"
require "mongoid/relations/metadata"
require "mongoid/relations/macros"

module Mongoid # :nodoc:
  module Relations #:nodoc:
    extend ActiveSupport::Concern
    include Accessors
    include Cascading
    include Cyclic
    include Builders
    include Macros
    include Polymorphic
    include Reflections

    included do
      attr_accessor :metadata
    end

    # Determine if the document itself is embedded in another document via the
    # proper channels. (If it has a parent document.)
    #
    # @example Is the document embedded?
    #   address.embedded?
    #
    # @return [ Boolean ] True if the document has a parent document.
    def embedded?
      _parent.present?
    end

    # Determine if the document is part of an embeds_many relation.
    #
    # @example Is the document in an embeds many?
    #   address.embedded_many?
    #
    # @return [ Boolean ] True if in an embeds many.
    def embedded_many?
      metadata && metadata.macro == :embeds_many
    end

    # Determine if the document is part of an embeds_one relation.
    #
    # @example Is the document in an embeds one?
    #   address.embedded_one?
    #
    # @return [ Boolean ] True if in an embeds one.
    def embedded_one?
      metadata && metadata.macro == :embeds_one
    end

    # Determine if the document is part of an references_many relation.
    #
    # @example Is the document in a references many?
    #   post.referenced_many?
    #
    # @return [ Boolean ] True if in a references many.
    def referenced_many?
      metadata && metadata.macro == :references_many
    end

    # Determine if the document is part of an references_one relation.
    #
    # @example Is the document in a references one?
    #   address.referenced_one?
    #
    # @return [ Boolean ] True if in a references one.
    def referenced_one?
      metadata && metadata.macro == :references_one
    end
  end
end
