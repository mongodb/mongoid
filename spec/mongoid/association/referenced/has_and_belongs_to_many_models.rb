# frozen_string_literal: true
# encoding: utf-8

class HabtmmCompany
  include Mongoid::Document

  field :c_id, type: Integer
  field :e_ids, type: Array
  has_and_belongs_to_many :employees, class_name: 'HabtmmEmployee',
    primary_key: :e_id, foreign_key: :e_ids,
    inverse_primary_key: :c_id, inverse_foreign_key: :c_ids
end

class HabtmmEmployee
  include Mongoid::Document

  field :e_id, type: Integer
  field :c_ids, type: Array
  field :habtmm_company_ids, type: Array
  has_and_belongs_to_many :companies, class_name: 'HabtmmCompany',
    primary_key: :c_id, foreign_key: :c_ids,
    inverse_primary_key: :e_id, inverse_foreign_key: :e_ids
end

class HabtmmContract
  include Mongoid::Document

  has_and_belongs_to_many :signatures, class_name: 'HabtmmSignature'

  field :item, type: String
end

class HabtmmSignature
  include Mongoid::Document

  has_and_belongs_to_many :contracts, class_name: 'HabtmmContract'

  field :name, type: String
  field :year, type: Integer
end

class HabtmmTicket
  include Mongoid::Document
end

class HabtmmPerson
  include Mongoid::Document

  has_and_belongs_to_many :tickets, class_name: 'HabtmmTicket'
end
