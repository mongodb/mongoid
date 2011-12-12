class Song
  include Mongoid::Document
  field :title
  embedded_in :artist
end
