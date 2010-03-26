# encoding: utf-8
module Mongoid #:nodoc:
  module Observable #:nodoc:
    extend ActiveSupport::Concern
    included do
      attr_reader :observers
    end

    # Add an observer to this object. This mimics the standard Ruby observable
    # library.
    #
    # Example:
    #
    # <tt>address.add_observer(person)</tt>
    def add_observer(object)
      @observers ||= []
      @observers.push(object)
    end

    # Notify all the objects observing this object of an update. All observers
    # need to respond to the update method in order to handle this.
    #
    # Example:
    #
    # <tt>document.notify_observers(self)</tt>
    def notify_observers(*args)
      @observers.dup.each { |observer| observer.observe(*args) } if @observers
    end
  end
end
