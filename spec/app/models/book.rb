class Book
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  field :title, type: String
  field :chapters, type: Integer
  belongs_to :series
  belongs_to :person, autobuild: true
  has_one :rating, as: :ratable, dependent: :nullify

  after_initialize do |doc|
    doc.chapters = 5
  end

  embeds_many :pages
end
