class Book
  include Mongoid::Document
  field :title, :type => String
  has_one :rating, :as => :ratable, :dependent => :nullify
end
