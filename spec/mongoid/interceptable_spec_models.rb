module InterceptableSpec
  class CallbackRegistry
    def initialize
      @calls = []
    end

    def record_call(cls, cb)
      @calls << [cls, cb]
    end

    attr_reader :calls
  end

  module CallbackTracking
    extend ActiveSupport::Concern

    included do
      %i(
        validation save create update
      ).each do |what|
        %i(before after).each do |whn|
          send("#{whn}_#{what}", "#{whn}_#{what}_stub".to_sym)
          define_method("#{whn}_#{what}_stub") do
            callback_registry.record_call(self.class, "#{whn}_#{what}".to_sym)
          end
        end
      end
    end
  end

  class CbParent
    include Mongoid::Document

    def initialize(callback_registry)
      @callback_registry = callback_registry
      super()
    end

    attr_reader :callback_registry

    embeds_many :cb_children
    embeds_many :cb_cascaded_children, cascade_callbacks: true

    include CallbackTracking
  end

  class CbChild
    include Mongoid::Document

    embedded_in :cb_parent

    def initialize(callback_registry, options)
      @callback_registry = callback_registry
      super(options)
    end

    attr_reader :callback_registry

    include CallbackTracking
  end

  class CbCascadedChild
    include Mongoid::Document

    embedded_in :cb_parent

    def initialize(callback_registry, options)
      @callback_registry = callback_registry
      super(options)
    end

    attr_reader :callback_registry

    include CallbackTracking
  end
end
