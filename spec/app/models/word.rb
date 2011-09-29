class Word
  include Mongoid::Document
  field :name, :type => String
  belongs_to :dictionary
  embeds_many :definitions, :validate => false
  embeds_one :pronunciation, :validate => false
end
