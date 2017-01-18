# encoding: utf-8
module Mongoid

  # This module provides the extra behaviour for including relations in JSON
  # and XML serialization.
  #
  # @since 4.0.0
  module Serializable
    extend ActiveSupport::Concern

    # We need to redefine where the JSON configuration is getting defined,
    # similar to +ActiveRecord+.
    included do
      undef_method :include_root_in_json
      delegate :include_root_in_json, to: ::Mongoid
    end

    # Gets the document as a serializable hash, used by ActiveModel's JSON
    # serializer.
    #
    # @example Get the serializable hash.
    #   document.serializable_hash
    #
    # @example Get the serializable hash with options.
    #   document.serializable_hash(:include => :addresses)
    #
    # @param [ Hash ] options The options to pass.
    #
    # @option options [ Symbol ] :include What relations to include.
    # @option options [ Symbol ] :only Limit the fields to only these.
    # @option options [ Symbol ] :except Dont include these fields.
    # @option options [ Symbol ] :methods What methods to include.
    #
    # @return [ Hash ] The document, ready to be serialized.
    #
    # @since 2.0.0.rc.6
    def serializable_hash(options = nil)
      options ||= {}
      attrs = {}

      names = field_names(options)

      method_names = Array.wrap(options[:methods]).map do |name|
        name.to_s if respond_to?(name)
      end.compact

      (names + method_names).each do |name|
        without_autobuild do
          serialize_attribute(attrs, name, names, options)
        end
      end
      serialize_relations(attrs, options) if options[:include]
      attrs
    end

    private

    # Get the names of all fields that will be serialized.
    #
    # @api private
    #
    # @example Get all the field names.
    #   document.send(:field_names)
    #
    # @return [ Array<String> ] The names of the fields.
    #
    # @since 3.0.0
    def field_names(options)
      names = (as_document.keys + attribute_names).uniq.sort

      only = Array.wrap(options[:only]).map(&:to_s)
      except = Array.wrap(options[:except]).map(&:to_s)
      except |= ['_type'] unless Mongoid.include_type_for_serialization

      if !only.empty?
        names &= only
      elsif !except.empty?
        names -= except
      end
      names
    end

    # Serialize a single attribute. Handles relations, fields, and dynamic
    # attributes.
    #
    # @api private
    #
    # @example Serialize the attribute.
    #   document.serialize_attribute({}, "id" , [ "id" ])
    #
    # @param [ Hash ] attrs The attributes.
    # @param [ String ] name The attribute name.
    # @param [ Array<String> ] names The names of all attributes.
    # @param [ Hash ] options The options.
    #
    # @return [ Object ] The attribute.
    #
    # @since 3.0.0
    def serialize_attribute(attrs, name, names, options)
      if relations.key?(name)
        value = send(name)
        attrs[name] = value ? value.serializable_hash(options) : nil
      elsif names.include?(name) && !fields.key?(name)
        attrs[name] = read_attribute(name)
      elsif !attribute_missing?(name)
        attrs[name] = send(name)
      end
    end

    # For each of the provided include options, get the relation needed and
    # provide it in the hash.
    #
    # @example Serialize the included relations.
    #   document.serialize_relations({}, :include => :addresses)
    #
    # @param [ Hash ] attributes The attributes to serialize.
    # @param [ Hash ] options The serialization options.
    #
    # @option options [ Symbol ] :include What relations to include
    # @option options [ Symbol ] :only Limit the fields to only these.
    # @option options [ Symbol ] :except Dont include these fields.
    #
    # @since 2.0.0.rc.6
    def serialize_relations(attributes = {}, options = {})
      inclusions = options[:include]
      relation_names(inclusions).each do |name|
        metadata = relations[name.to_s]
        if metadata && relation = send(metadata.name)
          attributes[metadata.name.to_s] =
            relation.serializable_hash(relation_options(inclusions, options, name))
        end
      end
    end

    # Since the inclusions can be a hash, symbol, or array of symbols, this is
    # provided as a convenience to parse out the names.
    #
    # @example Get the relation names.
    #   document.relation_names(:include => [ :addresses ])
    #
    # @param [ Hash, Symbol, Array<Symbol ] inclusions The inclusions.
    #
    # @return [ Array<Symbol> ] The names of the included relations.
    #
    # @since 2.0.0.rc.6
    def relation_names(inclusions)
      inclusions.is_a?(Hash) ? inclusions.keys : Array.wrap(inclusions)
    end

    # Since the inclusions can be a hash, symbol, or array of symbols, this is
    # provided as a convenience to parse out the options.
    #
    # @example Get the relation options.
    #   document.relation_names(:include => [ :addresses ])
    #
    # @param [ Hash, Symbol, Array<Symbol ] inclusions The inclusions.
    # @param [ Symbol ] name The name of the relation.
    #
    # @return [ Hash ] The options for the relation.
    #
    # @since 2.0.0.rc.6
    def relation_options(inclusions, options, name)
      if inclusions.is_a?(Hash)
        inclusions[name]
      else
        { except: options[:except], only: options[:only] }
      end
    end
  end
end
