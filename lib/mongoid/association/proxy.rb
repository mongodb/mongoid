# frozen_string_literal: true

require "mongoid/association/marshalable"

module Mongoid
  module Association

    # This class is the superclass for all association proxy objects, and contains
    # common behavior for all of them.
    class Proxy
      extend Forwardable

      alias :extend_proxy :extend

      # We undefine most methods to get them sent through to the target.
      instance_methods.each do |method|
        undef_method(method) unless
          method =~ /\A(?:__.*|send|object_id|equal\?|respond_to\?|respond_to_missing\?|tap|public_send|extend_proxy|extend_proxies)\z/
      end

      include Threaded::Lifecycle
      include Marshalable

      # Model instance for the base of the association.
      #
      # For example, if a Post embeds_many Comments, _base is a particular
      # instance of the Post model.
      attr_accessor :_base

      attr_accessor :_association

      # Model instance for one to one associations, or array of model instances
      # for one to many associations, for the target of the association.
      #
      # For example, if a Post embeds_many Comments, _target is an array of
      # Comment models embedded in a particular Post.
      attr_accessor :_target

      # Backwards compatibility with Mongoid beta releases.
      def_delegators :_association, :foreign_key, :inverse_foreign_key
      def_delegators :binding, :bind_one, :unbind_one
      def_delegator :_base, :collection_name

      # Convenience for setting the target and the association metadata properties since
      # all proxies will need to do this.
      #
      # @example Initialize the proxy.
      #   proxy.init(person, name, association)
      #
      # @param [ Document ] base The base document on the proxy.
      # @param [ Document | Array<Document> ] target The target of the proxy.
      # @param [ Association ] association The association metadata.
      def init(base, target, association)
        @_base, @_target, @_association = base, target, association
        yield(self) if block_given?
        extend_proxies(association.extension) if association.extension
      end

      # Allow extension to be an array and extend each module
      def extend_proxies(*extension)
        extension.flatten.each {|ext| extend_proxy(ext) }
      end

      # Get the class from the association, or return nil if no association present.
      #
      # @example Get the class.
      #   proxy.klass
      #
      # @return [ Class ] The association class.
      def klass
        _association ? _association.klass : nil
      end

      # Resets the criteria inside the association proxy. Used by many to many
      # associations to keep the underlying ids array in sync.
      #
      # @example Reset the association criteria.
      #   person.preferences.reset_relation_criteria
      def reset_unloaded
        _target.reset_unloaded(criteria)
      end

      # The default substitutable object for an association proxy is the clone of
      # the target.
      #
      # @example Get the substitutable.
      #   proxy.substitutable
      #
      # @return [ Object ] A clone of the target.
      def substitutable
        _target
      end

      protected

      # Get the collection from the root of the hierarchy.
      #
      # @example Get the collection.
      #   relation.collection
      #
      # @return [ Collection ] The root's collection.
      def collection
        root = _base._root
        root.collection unless root.embedded?
      end

      # Takes the supplied document and sets the association on it.
      #
      # @example Set the association metadata.
      #   proxt.characterize_one(name)
      #
      # @param [ Document ] document The document to set on.
      def characterize_one(document)
        document._association = _association unless document._association
      end

      # Default behavior of method missing should be to delegate all calls
      # to the target of the proxy. This can be overridden in special cases.
      #
      # @param [ String | Symbol ] name The name of the method.
      # @param [ Object... ] *args The arguments passed to the method.
      ruby2_keywords def method_missing(name, *args, &block)
        _target.send(name, *args, &block)
      end

      # @api private
      ruby2_keywords def respond_to_missing?(name, *args)
        _target.respond_to?(name, *args)
      end

      # When the base document illegally references an embedded document this
      # error will get raised.
      #
      # @example Raise the error.
      #   relation.raise_mixed
      #
      # @raise [ Errors::MixedRelations ] The error.
      def raise_mixed
        raise Errors::MixedRelations.new(_base.class, _association.klass)
      end

      # When the base is not yet saved and the user calls create or create!
      # on the association, this error will get raised.
      #
      # @example Raise the error.
      #   relation.raise_unsaved(post)
      #
      # @param [ Document ] doc The child document getting created.
      #
      # @raise [ Errors::UnsavedDocument ] The error.
      def raise_unsaved(doc)
        raise Errors::UnsavedDocument.new(_base, doc)
      end

      # Executes a callback method
      #
      # @example execute the before add callback
      #   execute_callback(:before_add)
      #
      # @param [ Symbol ] callback to be executed
      def execute_callback(callback, doc)
        _association.get_callbacks(callback).each do |c|
          if c.is_a? Proc
            c.call(_base, doc)
          else
            _base.send c, doc
          end
        end
      end

      # Execute the before and after callbacks for the given method.
      #
      # @param [ Symbol ] name The name of the callbacks to execute.
      #
      # @return [ Object ] The result of the given block
      def execute_callbacks_around(name, doc)
        execute_callback :"before_#{name.to_s}", doc
        yield.tap do
          execute_callback :"after_#{name.to_s}", doc
        end
      end

      class << self

        # Apply ordering to the criteria if it was defined on the association.
        #
        # @example Apply the ordering.
        #   Proxy.apply_ordering(criteria, association)
        #
        # @param [ Criteria ] criteria The criteria to modify.
        # @param [ Association ] association The association metadata.
        #
        # @return [ Criteria ] The ordered criteria.
        def apply_ordering(criteria, association)
          association.order ? criteria.order_by(association.order) : criteria
        end
      end
    end
  end
end
