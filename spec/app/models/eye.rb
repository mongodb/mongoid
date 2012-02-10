class Eye
  include Mongoid::Document
  
  field :pupil_dilation, type: Integer
  
  belongs_to :eyeable, polymorphic: true
end