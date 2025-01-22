module InterceptableSpec
  class CallbackRegistry
    def initialize(only: [])
      @calls = []
      @only = only
    end

    def record_call(cls, cb)
      return unless @only.empty? || @only.any? { |pat| pat == cb }
      @calls << [cls, cb]
    end

    def reset!
      @calls.clear
    end

    attr_reader :calls
  end

  module CallbackTracking
    extend ActiveSupport::Concern

    included do
      field :name, type: String

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

    attr_accessor :callback_registry

    def initialize(callback_registry, *args, **kwargs)
      @callback_registry = callback_registry
      super(*args, **kwargs)
    end
  end

  module RootInsertable
    def insert_as_root
      @callback_registry&.record_call(self.class, :insert_into_database)
      super
    end
  end

  class CbHasOneParent
    include Mongoid::Document
    include CallbackTracking
    include RootInsertable

    has_one :child, autosave: true, class_name: "CbHasOneChild", inverse_of: :parent
  end

  class CbHasOneChild
    include Mongoid::Document
    include CallbackTracking

    belongs_to :parent, class_name: "CbHasOneParent", inverse_of: :child
  end

  class CbHasManyParent
    include Mongoid::Document
    include CallbackTracking
    include RootInsertable

    has_many :children, autosave: true, class_name: "CbHasManyChild", inverse_of: :parent
  end

  class CbHasManyChild
    include Mongoid::Document
    include CallbackTracking

    belongs_to :parent, class_name: "CbHasManyParent", inverse_of: :children
  end

  class CbEmbedsOneParent
    include Mongoid::Document
    include CallbackTracking
    include RootInsertable

    field :name

    embeds_one :child, cascade_callbacks: true, class_name: "CbEmbedsOneChild", inverse_of: :parent
  end

  class CbEmbedsOneChild
    include Mongoid::Document
    include CallbackTracking

    field :age

    embedded_in :parent, class_name: "CbEmbedsOneParent", inverse_of: :child
  end

  class CbEmbedsManyParent
    include Mongoid::Document
    include CallbackTracking
    include RootInsertable

    embeds_many :children, cascade_callbacks: true, class_name: "CbEmbedsManyChild", inverse_of: :parent
  end

  class CbEmbedsManyChild
    include Mongoid::Document
    include CallbackTracking

    embedded_in :parent, class_name: "CbEmbedsManyParent", inverse_of: :children
  end

  class CbParent
    include Mongoid::Document
    include CallbackTracking

    embeds_many :cb_children
    embeds_many :cb_cascaded_children, cascade_callbacks: true
    embeds_many :cb_cascaded_nodes, cascade_callbacks: true, as: :parent
  end

  class CbChild
    include Mongoid::Document
    include CallbackTracking

    embedded_in :cb_parent
  end

  class CbCascadedChild
    include Mongoid::Document
    include CallbackTracking

    embedded_in :cb_parent

    before_save :test_mongoid_state

    private

    # Helps test that cascading child callbacks have access to the Mongoid
    # state objects; if the implementation uses fiber-local (instead of truly
    # thread-local) variables, the related tests will fail because the
    # cascading child callbacks use fibers to linearize the recursion.
    def test_mongoid_state
      Mongoid::Threaded.stack('interceptable').push(self)
    end
  end

  class CbCascadedNode
    include Mongoid::Document
    include CallbackTracking

    embedded_in :parent, polymorphic: true

    embeds_many :cb_cascaded_nodes, cascade_callbacks: true, as: :parent
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

class InterceptablePlane
  include Mongoid::Document

  has_many :wings, class_name: "InterceptableWing"
end

class InterceptableWing
  include Mongoid::Document

  belongs_to :plane, class_name: "InterceptablePlane"
  has_one :engine, autobuild: true, class_name: "InterceptableEngine"

  field :_id, type: String, default: -> { 'hello-wing' }

  field :p_id, type: String, default: -> { plane&.id }
  field :e_id, type: String, default: -> { engine&.id }
end

class InterceptableEngine
  include Mongoid::Document

  belongs_to :wing, class_name: "InterceptableWing"

  field :_id, type: String, default: -> { "hello-engine-#{wing&.id}" }
end

class InterceptableCompany
  include Mongoid::Document

  has_many :users, class_name: "InterceptableUser"
  has_many :shops, class_name: "InterceptableShop"
end

class InterceptableShop
  include Mongoid::Document

  embeds_one :address, class_name: "InterceptableAddress"
  belongs_to :company, class_name: "InterceptableCompany"

  after_initialize :build_address1

  def build_address1
    self.address ||= Address.new
  end
end

class InterceptableAddress
  include Mongoid::Document
  embedded_in :shop, class_name: "InterceptableShop"
end

class InterceptableUser
  include Mongoid::Document

  belongs_to :company, class_name: "InterceptableCompany"

  validate :break_mongoid

  def break_mongoid
    company.shop_ids
  end
end

