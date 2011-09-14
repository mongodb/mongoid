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

  class << self
    def alive
      criteria.where(:status => "Alive")
    end
  end
end
