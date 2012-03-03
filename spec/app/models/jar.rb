class Jar
  include Mongoid::Document
  field :_id, type: Integer
  has_many :cookies, class_name: "Cookie"
end
