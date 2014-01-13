# encoding: utf-8
require "mongoid/relations/accessors"
require "mongoid/relations/auto_save"
require "mongoid/relations/cascading"
require "mongoid/relations/constraint"
require "mongoid/relations/conversions"
require "mongoid/relations/counter_cache"
require "mongoid/relations/cyclic"
require "mongoid/relations/proxy"
require "mongoid/relations/bindings"
require "mongoid/relations/builders"
require "mongoid/relations/many"
require "mongoid/relations/one"
require "mongoid/relations/options"
require "mongoid/relations/polymorphic"
require "mongoid/relations/targets/enumerable"
require "mongoid/relations/embedded/in"
require "mongoid/relations/embedded/many"
require "mongoid/relations/embedded/one"
require "mongoid/relations/referenced/in"
require "mongoid/relations/referenced/many"
require "mongoid/relations/referenced/many_to_many"
require "mongoid/relations/referenced/one"
require "mongoid/relations/reflections"
require "mongoid/relations/synchronization"
require "mongoid/relations/touchable"
require "mongoid/relations/metadata"
require "mongoid/relations/macros"

module Mongoid

  # All classes and modules under the relations namespace handle the
  # functionality that has to do with embedded and referenced (relational)
  # associations.
  module Relations
    extend ActiveSupport::Concern
    include Accessors
    include AutoSave
    include Cascading
    include Cyclic
    include Builders
    include Macros
    include Polymorphic
    include Reflections
    include Synchronization
    include Touchable
    include CounterCache

    attr_accessor :__metadata
    alias :relation_metadata :__metadata

    # Determine if the document itself is embedded in another document via the
    # proper channels. (If it has a parent document.)
    #
    # @example Is the document embedded?
    #   address.embedded?
    #
    # @return [ true, false ] True if the document has a parent document.
    #
    # @since 2.0.0.rc.1
    def embedded?
      @embedded ||= (cyclic ? _parent.present? : self.class.embedded?)
    end

    # Determine if the document is part of an embeds_many relation.
    #
    # @example Is the document in an embeds many?
    #   address.embedded_many?
    #
    # @return [ true, false ] True if in an embeds many.
    #
    # @since 2.0.0.rc.1
    def embedded_many?
      __metadata && __metadata.macro == :embeds_many
    end

    # Determine if the document is part of an embeds_one relation.
    #
    # @example Is the document in an embeds one?
    #   address.embedded_one?
    #
    # @return [ true, false ] True if in an embeds one.
    #
    # @since 2.0.0.rc.1
    def embedded_one?
      __metadata && __metadata.macro == :embeds_one
    end

    # Get the metadata name for this document. If no metadata was defined
    # will raise an error.
    #
    # @example Get the metadata name.
    #   document.metadata_name
    #
    # @raise [ Errors::NoMetadata ] If no metadata is present.
    #
    # @return [ Symbol ] The metadata name.
    #
    # @since 3.0.0
    def metadata_name
      raise Errors::NoMetadata.new(self.class.name) unless __metadata
      __metadata.name
    end

    # Determine if the document is part of an references_many relation.
    #
    # @example Is the document in a references many?
    #   post.referenced_many?
    #
    # @return [ true, false ] True if in a references many.
    #
    # @since 2.0.0.rc.1
    def referenced_many?
      __metadata && __metadata.macro == :has_many
    end

    # Determine if the document is part of an references_one relation.
    #
    # @example Is the document in a references one?
    #   address.referenced_one?
    #
    # @return [ true, false ] True if in a references one.
    #
    # @since 2.0.0.rc.1
    def referenced_one?
      __metadata && __metadata.macro == :has_one
    end

    # Convenience method for iterating through the loaded relations and
    # reloading them.
    #
    # @example Reload the relations.
    #   document.reload_relations
    #
    # @return [ Hash ] The relations metadata.
    #
    # @since 2.1.6
    def reload_relations
      relations.each_pair do |name, meta|
        if instance_variable_defined?("@_#{name}")
          if _parent.nil? || instance_variable_get("@_#{name}") != _parent
            remove_instance_variable("@_#{name}")
          end
        end
      end
    end
  end
end
