# frozen_string_literal: true

class Audio
  include Mongoid::Document
  field :likes, type: :integer
  default_scope ->{ self.or({:likes => nil}, {:likes.gt => 100}) }
end
