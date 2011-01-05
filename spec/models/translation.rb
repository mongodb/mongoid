class Translation
  include Mongoid::Document
  field :language
  embedded_in :name
end
