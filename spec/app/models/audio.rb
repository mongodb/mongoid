class Audio
  include Mongoid::Document
  field :likes, type: Integer
  default_scope ->{ where(:likes.gt => 100) }
end
