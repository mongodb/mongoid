# frozen_string_literal: true

module Mongoid

  # This module contains all the callback hooks for Mongoid.
  module Interceptable
    extend ActiveSupport::Concern

    CALLBACKS = [
      :after_build,
      :after_create,
      :after_destroy,
      :after_find,
      :after_initialize,
      :after_save,
      :after_touch,
      :after_update,
      :after_upsert,
      :after_validation,
      :around_create,
      :around_destroy,
      :around_save,
      :around_update,
      :around_upsert,
      :before_create,
      :before_destroy,
      :before_save,
      :before_update,
      :before_upsert,
      :before_validation,
    ].freeze

    included do
      extend ActiveModel::Callbacks
      include ActiveModel::Validations::Callbacks

      define_model_callbacks :build, :find, :initialize, :touch, only: :after
      define_model_callbacks :create, :destroy, :save, :update, :upsert

      # This callback is used internally by Mongoid to save association
      # targets for referenced associations after the parent model is persisted.
      #
      # @api private
      define_model_callbacks :persist_parent

      attr_accessor :before_callback_halted
    end

    # Is the provided type of callback executable by this document?
    #
    # @example Is the callback executable?
    #   document.callback_executable?(:save)
    #
    # @param [ Symbol ] kind The type of callback.
    #
    # @return [ true | false ] If the callback can be executed.
    def callback_executable?(kind)
      respond_to?("_#{kind}_callbacks")
    end

    # Is the document currently in a state that could potentially require
    # callbacks to be executed?
    #
    # @example Is the document in a callback state?
    #   document.in_callback_state?(:update)
    #
    # @param [ Symbol ] kind The callback kind.
    #
    # @return [ true | false ] If the document is in a callback state.
    def in_callback_state?(kind)
      [ :create, :destroy ].include?(kind) || new_record? || flagged_for_destroy? || changed?
    end

    # Run only the after callbacks for the specific event.
    #
    # @note ActiveSupport does not allow this type of behavior by default, so
    #   Mongoid has to get around it and implement itself.
    #
    # @example Run only the after save callbacks.
    #   model.run_after_callbacks(:save)
    #
    # @param [ Symbol... ] *kinds The events that are occurring.
    #
    # @return [ Object ] The result of the chain executing.
    def run_after_callbacks(*kinds)
      kinds.each do |kind|
        run_targeted_callbacks(:after, kind)
      end
    end

    # Run only the before callbacks for the specific event.
    #
    # @note ActiveSupport does not allow this type of behavior by default, so
    #   Mongoid has to get around it and implement itself.
    #
    # @example Run only the before save callbacks.
    #   model.run_before_callbacks(:save, :create)
    #
    # @param [ Symbol... ] *kinds The events that are occurring.
    #
    # @return [ Object ] The result of the chain executing.
    def run_before_callbacks(*kinds)
      kinds.each do |kind|
        run_targeted_callbacks(:before, kind)
      end
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
    # @param [ true | false ] with_children Flag specifies whether callbacks of embedded document should be run.
    def run_callbacks(kind, with_children: true, &block)
      if with_children
        cascadable_children(kind).each do |child|
          if child.run_callbacks(child_callback_type(kind, child), with_children: with_children) == false
            return false
          end
        end
      end
      if callback_executable?(kind)
        super(kind, &block)
      else
        true
      end
    end

    # Run the callbacks for embedded documents.
    #
    # @param [ Symbol ] kind The type of callback to execute.
    # @param [ Array<Document> ] children Children to execute callbacks on. If
    #   nil, callbacks will be executed on all cascadable children of
    #   the document.
    #
    # @api private
    def _mongoid_run_child_callbacks(kind, children: nil, &block)
      child, *tail = (children || cascadable_children(kind))
      with_children = !Mongoid::Config.prevent_multiple_calls_of_embedded_callbacks
      if child.nil?
        block&.call
      elsif tail.empty?
        child.run_callbacks(child_callback_type(kind, child), with_children: with_children, &block)
      else
        child.run_callbacks(child_callback_type(kind, child), with_children: with_children) do
          _mongoid_run_child_callbacks(kind, children: tail, &block)
        end
      end
    end

    # This is used to store callbacks to be executed later. A good use case for
    # this is delaying the after_find and after_initialize callbacks until the
    # associations are set on the document. This can also be used to delay
    # applying the defaults on a document.
    #
    # @return [ Array<Symbol> ] an array of symbols that represent the pending callbacks.
    #
    # @api private
    def pending_callbacks
      @pending_callbacks ||= [].to_set
    end

    # @api private
    def pending_callbacks=(value)
      @pending_callbacks = value
    end

    # Run the pending callbacks. If the callback is :apply_defaults, we will apply
    # the defaults for this document. Otherwise, the callback is passed to the
    # run_callbacks function.
    #
    # @api private
    def run_pending_callbacks
      pending_callbacks.each do |cb|
        if [:apply_defaults, :apply_post_processed_defaults].include?(cb)
          send(cb)
        else
          self.run_callbacks(cb, with_children: false)
        end
      end
      pending_callbacks.clear
    end

    private

    # We need to hook into this for autosave, since we don't want it firing if
    # the before callbacks were halted.
    #
    # @api private
    #
    # @example Was a before callback halted?
    #   document.before_callback_halted?
    #
    # @return [ true | false ] If a before callback was halted.
    def before_callback_halted?
      !!@before_callback_halted
    end

    # Get all the child embedded documents that are flagged as cascadable.
    #
    # @example Get all the cascading children.
    #   document.cascadable_children(:update)
    #
    # @param [ Symbol ] kind The type of callback.
    #
    # @return [ Array<Document> ] The children.
    def cascadable_children(kind, children = Set.new)
      embedded_relations.each_pair do |name, association|
        next unless association.cascading_callbacks?
        without_autobuild do
          delayed_pulls = delayed_atomic_pulls[name]
          delayed_unsets = delayed_atomic_unsets[name]
          children.merge(delayed_pulls) if delayed_pulls
          children.merge(delayed_unsets) if delayed_unsets
          relation = send(name)
          Array.wrap(relation).each do |child|
            next if children.include?(child)
            children.add(child) if cascadable_child?(kind, child, association)
            child.send(:cascadable_children, kind, children)
          end
        end
      end
      children.to_a
    end

    # Determine if the child should fire the callback.
    #
    # @example Should the child fire the callback?
    #   document.cascadable_child?(:update, doc)
    #
    # @param [ Symbol ] kind The type of callback.
    # @param [ Document ] child The child document.
    #
    # @return [ true | false ] If the child should fire the callback.
    def cascadable_child?(kind, child, association)
      return false if kind == :initialize || kind == :find || kind == :touch
      return false if kind == :validate && association.validate?
      child.callback_executable?(kind) ? child.in_callback_state?(kind) : false
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
    def child_callback_type(kind, child)
      if kind == :update
        return :create if child.new_record?
        return :destroy if child.flagged_for_destroy?
        kind
      else
        kind
      end
    end

    # We need to hook into this for autosave, since we don't want it firing if
    # the before callbacks were halted.
    #
    # @api private
    #
    # @example Hook into the halt.
    #   document.halted_callback_hook(filter)
    #
    # @param [ Symbol ] filter The callback that halted.
    # @param [ Symbol ] name The name of the callback that was halted
    #   (requires Rails 6.1+)
    def halted_callback_hook(filter, name = nil)
      @before_callback_halted = true
    end

    # Run only the callbacks for the target location (before, after, around)
    # and kind (save, update, create).
    #
    # @example Run the targeted callbacks.
    #   model.run_targeted_callbacks(:before, :save)
    #
    # @param [ Symbol ] place The time to run, :before, :after, :around.
    # @param [ Symbol ] kind The type of callback, :save, :create, :update.
    #
    # @return [ Object ] The result of the chain execution.
    def run_targeted_callbacks(place, kind)
      name = "_run__#{place}__#{kind}__callbacks"
      unless respond_to?(name)
        chain = ActiveSupport::Callbacks::CallbackChain.new(name, {})
        send("_#{kind}_callbacks").each do |callback|
          chain.append(callback) if callback.kind == place
        end
        self.class.send :define_method, name do
          env = ActiveSupport::Callbacks::Filters::Environment.new(self, false, nil)
          sequence = chain.compile
          sequence.invoke_before(env)
          env.value = !env.halted
          sequence.invoke_after(env)
          env.value
        end
        self.class.send :protected, name
      end
      send(name)
    end
  end
end
