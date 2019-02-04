class HmmCompany
  include Mongoid::Document

  field :p, type: Integer
  has_many :emails, primary_key: :p, foreign_key: :f, class_name: 'HmmEmail'
end

class HmmEmail
  include Mongoid::Document

  field :f, type: Integer
  belongs_to :company, primary_key: :p, foreign_key: :f, class_name: 'HmmCompany'
end
