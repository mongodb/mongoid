class Jar
  include Mongoid::Document
  include Mongoid::Timestamps::Updated

  field :_id, type: Integer
  has_many :cookies, class_name: "Cookie"
end
