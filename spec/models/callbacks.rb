class Artist
  include Mongoid::Document
  field :name
  embeds_many :songs
  embeds_many :labels, :cascade_callbacks => true
  embeds_one  :instrument, :cascade_callbacks => true
  embeds_one  :address

  before_create :before_create_stub
  after_create :create_songs

  protected
  def before_create_stub
    true
  end

  def create_songs
    2.times { |n| songs.create!(:title => "#{n}") }
  end
end

class Address
  include Mongoid::Document
  field :street
  embedded_in :artist

  after_save :after_save_stub

  private
  def after_save_stub
  end
end

class Instrument
  include Mongoid::Document
  field :name
  field :key
  embedded_in :artist

  after_save :after_save_stub
  before_create :upcase_name
  before_update :tune_to_g_sharp

  private
  def after_save_stub; end
  def upcase_name
    self.name = self.name.upcase
  end
  def tune_to_g_sharp
    self.key = "G#"
  end
end

class Song
  include Mongoid::Document
  field :title
  embedded_in :artist

  after_save :after_save_stub

  private
  def after_save_stub
  end
end

class Label
  include Mongoid::Document
  field :name
  embedded_in :artist
  before_validation :cleanup

  after_save :after_save_stub

  private
  def cleanup
    self.name = self.name.downcase.capitalize
  end

  def after_save_stub
  end
end

class ValidationCallback
  include Mongoid::Document
  field :history, :type => Array, :default => []
  validate do
    self.history << :validate
  end

  before_validation { self.history << :before_validation }
  after_validation { self.history << :after_validation }
end
