class HabtmmCompany
  include Mongoid::Document

  field :c_id, type: Integer
  field :e_ids, type: Array
  has_and_belongs_to_many :employees, primary_key: :e_id, foreign_key: :e_ids, class_name: 'HabtmmEmployee'
end

class HabtmmEmployee
  include Mongoid::Document

  field :e_id, type: Integer
  field :c_ids, type: Array
  field :habtmm_company_ids, type: Array
  has_and_belongs_to_many :companies, primary_key: :c_id, foreign_key: :c_ids, class_name: 'HabtmmCompany'
end

class HabtmmTicket
  include Mongoid::Document
end

class HabtmmPerson
  include Mongoid::Document

  has_and_belongs_to_many :tickets, class_name: 'HabtmmTicket'
end
