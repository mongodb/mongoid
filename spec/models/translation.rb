class Translation
  include Mongoid::Document
  field :language
  embedded_in :name, :inverse_of => :translations
end
