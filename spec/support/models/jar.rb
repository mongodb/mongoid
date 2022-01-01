# frozen_string_literal: true

class Jar
  include Mongoid::Document
  include Mongoid::Timestamps::Updated

  field :_id, type: :integer, overwrite: true
  has_many :cookies, class_name: "Cookie"
end
