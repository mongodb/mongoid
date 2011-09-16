class Jar
  include Mongoid::Document
  identity :type => Integer
  has_many :cookies, :class_name => "Cookie"
end
