class Bar
  include Mongoid::Document
  field :name, :type => String
  references_one :rating, :as => :ratable
end
