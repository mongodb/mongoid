# encoding: utf-8
module Mongoid #:nodoc:

  # Mongoid observers hook into the lifecycle of documents.
  class Observer < ActiveModel::Observer

    # Instantiate the new observer. Will add all child observers as well.
    #
    # @example Instantiate the observer.
    #   Mongoid::Observer.new
    #
    # @since 2.0.0
    def initialize
      super and observed_descendants.each { |klass| add_observer!(klass) }
    end

    protected

    # Get all the child observers.
    #
    # @example Get the children.
    #   observer.observed_descendants
    #
    # @return [ Array<Class> ] The children.
    #
    # @since 2.0.0
    def observed_descendants
      observed_classes.sum([]) { |klass| klass.descendants }
    end

    # Adds the specified observer to the class.
    #
    # @example Add the observer.
    #   observer.add_observer!(Document)
    #
    # @param [ Class ] klass The child observer to add.
    #
    # @since 2.0.0
    def add_observer!(klass)
      super and define_callbacks(klass)
    end

    # Defines all the callbacks for each observer of the model.
    #
    # @example Define all the callbacks.
    #   observer.define_callbacks(Document)
    #
    # @param [ Class ] klass The model to define them on.
    #
    # @since 2.0.0
    def define_callbacks(klass)
      tap do |observer|
        observer_name = observer.class.name.underscore.gsub('/', '__')
        Mongoid::Callbacks::CALLBACKS.each do |callback|
          next unless respond_to?(callback)
          callback_meth = :"_notify_#{observer_name}_for_#{callback}"
          unless klass.respond_to?(callback_meth)
            klass.send(:define_method, callback_meth) do |&block|
              observer.send(callback, self, &block)
            end
            klass.send(callback, callback_meth)
          end
        end
      end
    end
  end
end
