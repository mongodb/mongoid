# frozen_string_literal: true

class Favorite
  include Mongoid::Document
  field :title
  validates_uniqueness_of :title, case_sensitive: false
  embedded_in :perp, class_name: "Person", inverse_of: :favorites
end
