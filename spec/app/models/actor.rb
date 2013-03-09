class Actor
  include Mongoid::Document
  field :name
  field :after_custom_count, type: Integer, default: 0
  has_and_belongs_to_many :tags
  embeds_many :things, validate: false, cascade_callbacks: true
  accepts_nested_attributes_for :things, allow_destroy: true

  define_model_callbacks :custom

  def do_something
    run_callbacks(:custom) do
      self.name = "custom"
    end
  end
end

require "app/models/actress"
