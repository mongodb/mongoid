class Face
  include Mongoid::Document
  
  has_one :left_eye, class_name: "Eye", as: :eyeable
  has_one :right_eye, class_name: "Eye", as: :eyeable
end