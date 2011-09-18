class Album
  include Mongoid::Document

  belongs_to :artist
  before_destroy :set_parent_name

  private

  def set_parent_name
    artist.name = "destroyed"
  end
end
