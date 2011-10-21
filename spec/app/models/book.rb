class Book
  include Mongoid::Document
  field :title, :type => String
  field :chapters, :type => Integer
  belongs_to :series
  has_one :rating, :as => :ratable, :dependent => :nullify
  belongs_to :person, :autobuild => true

  after_initialize do |doc|
    doc.chapters = 5
  end
end
