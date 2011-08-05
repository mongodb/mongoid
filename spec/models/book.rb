class Book
  include Mongoid::Document
  field :title, :type => String
  field :chapters, :type => Integer
  has_one :rating, :as => :ratable, :dependent => :nullify

  after_initialize do |doc|
    doc.chapters = 5
  end
end
