class Audio
  include Mongoid::Document
  field :likes, type: Integer
  default_scope ->{ self.or({:likes => nil}, {:likes.gt => 100}) }
end
