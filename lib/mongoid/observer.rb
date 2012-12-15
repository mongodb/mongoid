# encoding: utf-8
module Mongoid

  # Observer classes respond to life cycle callbacks to implement trigger-like
  # behavior outside the original class. This is a great way to reduce the
  # clutter that normally comes when the model class is burdened with
  # functionality that doesn't pertain to the core responsibility of the
  # class. Mongoid's observers work similar to ActiveRecord's. Example:
  #
  #   class CommentObserver < Mongoid::Observer
  #     def after_save(comment)
  #       Notifications.comment(
  #         "admin@do.com", "New comment was posted", comment
  #       ).deliver
  #     end
  #   end
  #
  # This Observer sends an email when a Comment#save is finished.
  #
  #   class ContactObserver < Mongoid::Observer
  #     def after_create(contact)
  #       contact.logger.info('New contact added!')
  #     end
  #
  #     def after_destroy(contact)
  #       contact.logger.warn("Contact with an id of #{contact.id} was destroyed!")
  #     end
  #   end
  #
  # This Observer uses logger to log when specific callbacks are triggered.
  #
  # == Observing a class that can't be inferred
  #
  # Observers will by default be mapped to the class with which they share a
  # name. So CommentObserver will be tied to observing Comment,
  # ProductManagerObserver to ProductManager, and so on. If you want to
  # name your observer differently than the class you're interested in
  # observing, you can use the Observer.observe class method which takes
  # either the concrete class (Product) or a symbol for that class (:product):
  #
  #   class AuditObserver < Mongoid::Observer
  #     observe :account
  #
  #     def after_update(account)
  #       AuditTrail.new(account, "UPDATED")
  #     end
  #   end
  #
  # If the audit observer needs to watch more than one kind of object,
  # this can be specified with multiple arguments:
  #
  #   class AuditObserver < Mongoid::Observer
  #     observe :account, :balance
  #
  #     def after_update(record)
  #       AuditTrail.new(record, "UPDATED")
  #     end
  #   end
  #
  # The AuditObserver will now act on both updates to Account and Balance
  # by treating them both as records.
  #
  # == Available callback methods
  #
  # * after_initialize
  # * before_validation
  # * after_validation
  # * before_create
  # * around_create
  # * after_create
  # * before_update
  # * around_update
  # * after_update
  # * before_upsert
  # * around_upsert
  # * after_upsert
  # * before_save
  # * around_save
  # * after_save
  # * before_destroy
  # * around_destroy
  # * after_destroy
  #
  # == Storing Observers in Rails
  #
  # If you're using Mongoid within Rails, observer classes are usually stored
  # in +app/models+ with the naming convention of +app/models/audit_observer.rb+.
  #
  # == Configuration
  #
  # In order to activate an observer, list it in the +config.mongoid.observers+
  # configuration setting in your +config/application.rb+ file.
  #
  #   config.mongoid.observers = :comment_observer, :signup_observer
  #
  # Observers will not be invoked unless you define them in your
  # application configuration.
  #
  # == Loading
  #
  # Observers register themselves with the model class that they observe,
  # since it is the class that notifies them of events when they occur.
  # As a side-effect, when an observer is loaded, its corresponding model
  # class is loaded.
  #
  # Observers are loaded after the application initializers, so that
  # observed models can make use of extensions. If by any chance you are
  # using observed models in the initialization, you can
  # still load their observers by calling +ModelObserver.instance+ before.
  # Observers are singletons and that call instantiates and registers them.
  class Observer < ActiveModel::Observer

    private

    # Adds the specified observer to the class.
    #
    # @example Add the observer.
    #   observer.add_observer!(Document)
    #
    # @param [ Class ] klass The child observer to add.
    #
    # @since 2.0.0.rc.8
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
    # @since 2.0.0.rc.8
    def define_callbacks(klass)
      observer = self
      observer_name = observer.class.name.underscore.gsub('/', '__')
      Mongoid::Callbacks.observables.each do |callback|
        next unless respond_to?(callback)
        callback_meth = :"_notify_#{observer_name}_for_#{callback}"
        unless klass.respond_to?(callback_meth)
          klass.send(:define_method, callback_meth) do |&block|
            if value = observer.update(callback, self, &block)
              value
            else
              block.call if block
            end
          end
          klass.send(callback, callback_meth)
        end
      end
      self
    end

    # Are the observers disabled for the object?
    #
    # @api private
    #
    # @example If the observer disabled?
    #   Observer.disabled_for(band)
    #
    # @param [ Document ] object The model instance.
    #
    # @return [ true, false ] If the observer is disabled.
    def disabled_for?(object)
      klass = object.class
      return false unless klass.respond_to?(:observers)
      klass.observers.disabled_for?(self) || Mongoid.observers.disabled_for?(self)
    end

    class << self

      # Attaches the observer to the specified classes.
      #
      # @example Attach the BandObserver to the class Artist.
      #   class BandObserver < Mongoid::Observer
      #     observe :artist
      #   end
      #
      # @param [ Array<Symbol> ] models The names of the models.
      #
      # @since 3.0.15
      def observe(*models)
        models.flatten!
        models.collect! do |model|
          model.respond_to?(:to_sym) ? model.to_s.camelize.constantize : model
        end
        singleton_class.redefine_method(:observed_classes) { models }
      end
    end
  end
end
