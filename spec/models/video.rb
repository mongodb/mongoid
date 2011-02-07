class Video
  include Mongoid::Document
  field :title
  embedded_in :person
  referenced_in :post
end
