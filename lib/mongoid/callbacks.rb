# encoding: utf-8
module Mongoid #:nodoc:

  # This module contains all the callback hooks for Mongoid.
  module Callbacks
    extend ActiveSupport::Concern

    CALLBACKS = [
      :before_validation, :after_validation,
      :after_initialize, :after_build,
      :before_create, :around_create, :after_create,
      :before_destroy, :around_destroy, :after_destroy,
      :before_save, :around_save, :after_save,
      :before_update, :around_update, :after_update,
    ]

    included do
      extend ActiveModel::Callbacks
      include ActiveModel::Validations::Callbacks

      define_model_callbacks :initialize, :only => :after
      define_model_callbacks :build, :only => :after
      define_model_callbacks :create, :destroy, :save, :update
    end

    # Run the callbacks for the document. This overrides active support's
    # functionality to cascade callbacks to embedded documents that have been
    # flagged as such.
    #
    # @example Run the callbacks.
    #   run_callbacks :save do
    #     save!
    #   end
    #
    # @param [ Symbol ] kind The type of callback to execute.
    # @param [ Array ] *args Any options.
    #
    # @return [ Document ] The document
    #
    # @since 2.3.0
    def run_callbacks(kind, *args, &block)
      run_cascading_callbacks(cascadable_children(kind), kind, *args) {}
      super(kind, *args, &block)
    end

    private

    # Execute the callbacks, including all children that have cascade callbacks
    # set to true.
    #
    # @example Run the cascading callbacks.
    #   document.run_cascading_callbacks([], :update)
    #
    # @param [ Array<Document> ] children The cascading children.
    # @param [ Symbol ] kind The callback type.
    # @param [ Array ] args The options.
    #
    # @since 2.3.0
    def run_cascading_callbacks(children, kind, *args, &block)
      if child = children.pop
        run_cascading_callbacks(children, kind, *args) do
          child.run_callbacks(child_callback_type(kind, child), *args) do
            block.call
          end
        end
      else
        block.call
      end
    end

    # Get all the child embedded documents that are flagged as cascadable.
    #
    # @example Get all the cascading children.
    #   document.cascadable_children(:update)
    #
    # @param [ Symbol ] kind The type of callback.
    #
    # @return [ Array<Document> ] The children.
    #
    # @since 2.3.0
    def cascadable_children(kind)
      [].tap do |children|
        relations.each_pair do |name, metadata|
          next unless metadata.cascading_callbacks?
          delayed_pulls = delayed_atomic_pulls[name]
          children.concat(delayed_pulls) if delayed_pulls
          child = send(name)
          Array.wrap(child).each do |doc|
            children.push(doc) if cascadable_child?(kind, doc)
            children.concat(doc.send(:cascadable_children, kind))
          end
        end
      end
    end

    # Determine if the child should fire the callback.
    #
    # @example Should the child fire the callback?
    #   document.cascadable_child?(:update, doc)
    #
    # @param [ Symbol ] kind The type of callback.
    # @param [ Document ] child The child document.
    #
    # @return [ true, false ] If the child should fire the callback.
    #
    # @since 2.3.0
    def cascadable_child?(kind, child)
      return false if kind == :initialize || !child.respond_to?("_#{kind}_callbacks")
      [ :create, :destroy ].include?(kind) || child.changed? || child.new_record?
    end

    # Get the name of the callback that the child should fire. This changes
    # depending on whether or not the child is new. A persisted parent with a
    # new child would fire :update from the parent, but needs to fire :create
    # on the child.
    #
    # @example Get the callback type.
    #   document.child_callback_type(:update, doc)
    #
    # @param [ Symbol ] kind The type of callback.
    # @param [ Document ] child The child document
    #
    # @return [ Symbol ] The name of the callback.
    #
    # @since 2.3.0
    def child_callback_type(kind, child)
      if kind == :update
        return :create if child.new_record?
        return :destroy if child.flagged_for_destroy?
        kind
      else
        kind
      end
    end
  end
end
