class Cookie
  include Mongoid::Document
  belongs_to :jar
end
