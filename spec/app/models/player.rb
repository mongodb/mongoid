class Player
  include Mongoid::Document
  field :active, :type => Boolean
  field :frags, :type => Integer
  field :deaths, :type => Integer
  field :status

  named_scope :active, criteria.where(:active => true) do
    def extension
      "extension"
    end
  end
  named_scope :inactive, :where => { :active => false }
  named_scope :frags_over, lambda { |count| { :where => { :frags.gt => count } } }
  named_scope :deaths_under, lambda { |count| criteria.where(:deaths.lt => count) }
  scope :deaths_over, lambda { |count| criteria.where(:deaths.gt => count) }

  references_many :weapons
  references_one :powerup

  embeds_many :implants
  embeds_one :augmentation

  class << self
    def alive
      criteria.where(:status => "Alive")
    end
  end
end

class Weapon
  include Mongoid::Document
  
  field :name
  
  referenced_in :player, :inverse_of => :weapons
  
  after_build do
    self.name = "Holy Hand Grenade (#{player.frags})"
  end
end

class Powerup
  include Mongoid::Document

  field :name

  referenced_in :player, :inverse_of => :powerup

  after_build do
    self.name = "Quad Damage (#{player.frags})"
  end
end

class Implant
  include Mongoid::Document

  field :name

  embedded_in :player, :inverse_of => :Implants

  after_build do
    self.name = "Cochlear Implant (#{player.frags})"
  end
end

class Augmentation
  include Mongoid::Document

  field :name

  embedded_in :player, :inverse_of => :augmentation

  after_build do
    self.name = "Infolink (#{player.frags})"
  end
end

