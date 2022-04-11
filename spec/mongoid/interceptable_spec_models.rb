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
            callback_registry&.record_call(self.class, "#{whn}_#{what}".to_sym)
          end
        end
        unless what == :validation
          send("around_#{what}", "around_#{what}_stub".to_sym)
          define_method("around_#{what}_stub") do |&block|
            callback_registry&.record_call(self.class, "around_#{what}_open".to_sym)
            block.call
            callback_registry&.record_call(self.class, "around_#{what}_close".to_sym)
          end
        end
      end
    end
  end

  class CbHasOneParent
    include Mongoid::Document

    has_one :child, autosave: true, class_name: "CbHasOneChild", inverse_of: :parent

    def initialize(callback_registry)
      @callback_registry = callback_registry
      super()
    end

    attr_accessor :callback_registry

    def insert_as_root
      @callback_registry&.record_call(self.class, :insert_into_database)
      super
    end

    include CallbackTracking
  end

  class CbHasOneChild
    include Mongoid::Document

    belongs_to :parent, class_name: "CbHasOneParent", inverse_of: :child

    def initialize(callback_registry)
      @callback_registry = callback_registry
      super()
    end

    attr_accessor :callback_registry

    include CallbackTracking
  end

  class CbHasManyParent
    include Mongoid::Document

    has_many :children, autosave: true, class_name: "CbHasManyChild", inverse_of: :parent

    def initialize(callback_registry)
      @callback_registry = callback_registry
      super()
    end

    attr_accessor :callback_registry

    def insert_as_root
      @callback_registry&.record_call(self.class, :insert_into_database)
      super
    end

    include CallbackTracking
  end

  class CbHasManyChild
    include Mongoid::Document

    belongs_to :parent, class_name: "CbHasManyParent", inverse_of: :children

    def initialize(callback_registry)
      @callback_registry = callback_registry
      super()
    end

    attr_accessor :callback_registry

    include CallbackTracking
  end

  class CbEmbedsOneParent
    include Mongoid::Document

    field :name

    embeds_one :child, cascade_callbacks: true, class_name: "CbEmbedsOneChild", inverse_of: :parent

    def initialize(callback_registry)
      @callback_registry = callback_registry
      super()
    end

    attr_accessor :callback_registry

    def insert_as_root
      @callback_registry&.record_call(self.class, :insert_into_database)
      super
    end

    include CallbackTracking
  end

  class CbEmbedsOneChild
    include Mongoid::Document

    field :age

    embedded_in :parent, class_name: "CbEmbedsOneParent", inverse_of: :child

    def initialize(callback_registry)
      @callback_registry = callback_registry
      super()
    end

    attr_accessor :callback_registry

    include CallbackTracking
  end

  class CbEmbedsManyParent
    include Mongoid::Document

    embeds_many :children, cascade_callbacks: true, class_name: "CbEmbedsManyChild", inverse_of: :parent

    def initialize(callback_registry)
      @callback_registry = callback_registry
      super()
    end

    attr_accessor :callback_registry

    def insert_as_root
      @callback_registry&.record_call(self.class, :insert_into_database)
      super
    end

    include CallbackTracking
  end

  class CbEmbedsManyChild
    include Mongoid::Document

    embedded_in :parent, class_name: "CbEmbedsManyParent", inverse_of: :children

    def initialize(callback_registry)
      @callback_registry = callback_registry
      super()
    end

    attr_accessor :callback_registry

    include CallbackTracking
  end

  class CbParent
    include Mongoid::Document

    def initialize(callback_registry)
      @callback_registry = callback_registry
      super()
    end

    attr_accessor :callback_registry

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

    attr_accessor :callback_registry

    include CallbackTracking
  end

  class CbCascadedChild
    include Mongoid::Document

    embedded_in :cb_parent

    def initialize(callback_registry, options)
      @callback_registry = callback_registry
      super(options)
    end

    attr_accessor :callback_registry

    include CallbackTracking
  end
end

class InterceptableBand
  include Mongoid::Document

  has_many :songs, class_name: "InterceptableSong"
  field :name
end

class InterceptableSong
  include Mongoid::Document

  belongs_to :band, class_name: "InterceptableBand"
  field :band_name, default: -> { band.name }
  field :name
end
