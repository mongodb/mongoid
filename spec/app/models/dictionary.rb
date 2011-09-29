class Dictionary
  include Mongoid::Document
  field :name, :type => String
  field :publisher, :type => String
  field :year, :type => Integer
  field :published, :type => Time
  has_many :words, :validate => false
end
