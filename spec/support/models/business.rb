# frozen_string_literal: true
# rubocop:todo all

class Business
  include Mongoid::Document
  field :name, type: String
  has_and_belongs_to_many :owners, class_name: "User", validate: false
end
