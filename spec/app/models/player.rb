class Player
  include Mongoid::Document
  field :active, :type => Boolean
  field :frags, :type => Integer
  field :deaths, :type => Integer
  field :status

  scope :active, where(:active => true) do
    def extension
      "extension"
    end
  end

  scope :inactive, where(:active => false)
  scope :frags_over, lambda { |count| where(:frags.gt => count) }
  scope :deaths_under, lambda { |count| where(:deaths.lt => count) }
  scope :deaths_over, lambda { |count| where(:deaths.gt => count) }

  has_many :weapons
  has_one :powerup

  embeds_many :implants
  embeds_one :augmentation

  class << self
    def alive
      where(:status => "Alive")
    end
  end
end
