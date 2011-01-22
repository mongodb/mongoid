class Owner
  include Mongoid::Document
  field :name
  references_many :events
  embeds_many :birthdays
end
