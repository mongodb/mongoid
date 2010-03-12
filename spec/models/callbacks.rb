class Artist
  include Mongoid::Document
  field :name
  has_many :songs

  after_create :create_songs

  protected
  def create_songs
    2.times { |n| songs.create!(:title => "#{n}") }
  end
end

class Song
  include Mongoid::Document
  field :title
  belongs_to :artist, :inverse_of => :songs
end
