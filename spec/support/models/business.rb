# frozen_string_literal: true

class Business
  include Mongoid::Document
  field :name, type: :string
  has_and_belongs_to_many :owners, class_name: "User", validate: false
end
