class Song
  include Mongoid::Document
  field :title
  embedded_in :artist

  attr_accessor :before_add_called

end
