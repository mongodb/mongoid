class Book
  include Mongoid::Document
  field :title, :type => String
  references_one :rating, :as => :ratable, :dependent => :nullify
end
