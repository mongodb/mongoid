# encoding: utf-8
module Mongoid #:nodoc:
  class Observer < ActiveModel::Observer
    def initialize
      super
      observed_descendants.each { |klass| add_observer!(klass) }
    end

    protected

    def observed_descendants
      observed_classes.sum([]) { |klass| klass.descendants }
    end

    def add_observer!(klass)
      super
      define_callbacks klass
    end

    def define_callbacks(klass)
      observer = self
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
