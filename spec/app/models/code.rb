class Code
  include Mongoid::Document
  field :name, type: String
  embedded_in :address
end
