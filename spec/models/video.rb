class Video
  include Mongoid::Document
  field :title
  embedded_in :person, :inverse_of => :videos
end
