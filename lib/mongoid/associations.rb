require 'mongoid/associations/accessors'
require 'mongoid/associations/builders'
require 'mongoid/associations/bindable'
require 'mongoid/associations/depending'
require 'mongoid/associations/macros'
require 'mongoid/associations/proxy'
require 'mongoid/associations/touchable'

require 'mongoid/associations/many'
require 'mongoid/associations/one'
require 'mongoid/associations/macros'
require 'mongoid/associations/relatable'

require 'mongoid/associations/nested'
require 'mongoid/associations/referenced'
require 'mongoid/associations/embedded'

require 'mongoid/associations/reflections'
require 'mongoid/associations/eager_loadable'

module Mongoid
  module Associations
    extend ActiveSupport::Concern
    include Embedded::Cyclic
    include Referenced::AutoSave
    include Referenced::CounterCache
    include Referenced::Syncable
    include Accessors
    include Depending
    include Builders
    include Macros
    include Reflections

    attr_accessor :__metadata
    alias :relation_metadata :__metadata

    included do
      class_attribute :polymorphic
      self.polymorphic = false
    end

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