class HomCollege
  include Mongoid::Document

  has_one :accreditation, class_name: 'HomAccreditation'

  field :state, type: String
end

class HomAccreditation
  include Mongoid::Document

  belongs_to :college, class_name: 'HomCollege'

  field :degree, type: String
  field :year, type: Integer, default: 2012
end
