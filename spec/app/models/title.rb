class Title
  include Mongoid::Document
  belongs_to :paranoid_post
end
