class Owner
  include Mongoid::Document
  field :name
  has_many :events
  embeds_many :birthdays
end
