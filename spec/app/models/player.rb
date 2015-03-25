class Player
  include Mongoid::Document
  field :active, type: Mongoid::Boolean
  field :frags, type: Integer
  field :deaths, type: Integer
  field :impressions, type: Integer, default: 0
  field :status

  scope :active, ->{ where(active: true) } do
    def extension
      "extension"
    end
  end

  scope :inactive, ->{ where(active: false) }
  scope :frags_over, ->(count) { where(:frags.gt => count) }
  scope :deaths_under, ->(count) { where(:deaths.lt => count) }
  scope :deaths_over, ->(count) { where(:deaths.gt => count) }

  has_many :weapons
  has_one :powerup

  embeds_many :implants
  embeds_one :augmentation

  after_find do |doc|
    doc.impressions += 1
  end

  class << self
    def alive
      where(status: "Alive")
    end
  end
end
