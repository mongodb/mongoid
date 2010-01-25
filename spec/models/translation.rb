class Translation
  include Mongoid::Document
  field :language
  belongs_to :name, :inverse_of => :translations
end