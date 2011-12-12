class Artist
  include Mongoid::Document

  field :name, :type => String

  embeds_many :songs
  embeds_many :labels
  has_many :albums, :dependent => :destroy

  before_create :before_create_stub
  after_create :create_songs
  before_save :before_save_stub
  before_destroy :before_destroy_stub

  protected
  def before_create_stub
    true
  end

  def before_save_stub
    true
  end

  def before_destroy_stub
    true
  end

  def create_songs
    2.times { |n| songs.create!(:title => "#{n}") }
  end
end
