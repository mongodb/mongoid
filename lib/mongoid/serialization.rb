# encoding: utf-8
module Mongoid

  # This module provides the extra behaviour for including relations in JSON
  # and XML serialization.
  module Serialization
    extend ActiveSupport::Concern

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

      only   = Array.wrap(options[:only]).map(&:to_s)
      except = Array.wrap(options[:except]).map(&:to_s)

      except |= ['_type'] unless Mongoid.include_type_for_serialization

      field_names = self.class.attribute_names
      attribute_names = (as_document.keys + field_names).sort
      if !only.empty?
        attribute_names &= only
      elsif !except.empty?
        attribute_names -= except
      end

      method_names = Array.wrap(options[:methods]).map do |name|
        name.to_s if respond_to?(name)
      end.compact

      attrs = {}
      (attribute_names + method_names).each do |name|
        without_autobuild do
          if relations.has_key?(name)
            value = send(name)
            attrs[name] = value ? value.serializable_hash(options) : nil
          elsif attribute_names.include?(name) && !fields.has_key?(name)
            attrs[name] = read_attribute(name)
          else
            attrs[name] = send(name)
          end
        end
      end
      serialize_relations(attrs, options) if options[:include]
      attrs
    end

    private

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
