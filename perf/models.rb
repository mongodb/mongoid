class Person
  include Mongoid::Document

  field :birth_date, :type => Date
  field :title, :type => String

  embeds_one :name, :validate => false
  embeds_many :addresses, :validate => false

  has_many :posts, :validate => false
  has_one :game, :validate => false
  has_and_belongs_to_many :preferences, :validate => false

  index preference_ids: 1
end

class Name
  include Mongoid::Document

  field :given, :type => String
  field :family, :type => String
  field :middle, :type => String
  embedded_in :person
end

class Address
  include Mongoid::Document

  field :street, :type => String
  field :city, :type => String
  field :state, :type => String
  field :post_code, :type => String
  field :address_type, :type => String
  embedded_in :person
end

class Post
  include Mongoid::Document

  field :title, :type => String
  field :content, :type => String
  belongs_to :person

  index person_id: 1
end

class Game
  include Mongoid::Document

  field :name, :type => String
  belongs_to :person

  index person_id: 1
end

class Preference
  include Mongoid::Document

  field :name, :type => String
  has_and_belongs_to_many :people, :validate => false

  index person_ids: 1
end
