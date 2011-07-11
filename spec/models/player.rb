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