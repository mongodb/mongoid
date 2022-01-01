# frozen_string_literal: true

class HabtmmCompany
  include Mongoid::Document

  field :c_id, type: :integer
  field :e_ids, type: :array
  has_and_belongs_to_many :employees, class_name: 'HabtmmEmployee',
    primary_key: :e_id, foreign_key: :e_ids,
    inverse_primary_key: :c_id, inverse_foreign_key: :c_ids
end

class HabtmmEmployee
  include Mongoid::Document

  field :e_id, type: :integer
  field :c_ids, type: :array
  field :habtmm_company_ids, type: :array
  has_and_belongs_to_many :companies, class_name: 'HabtmmCompany',
    primary_key: :c_id, foreign_key: :c_ids,
    inverse_primary_key: :e_id, inverse_foreign_key: :e_ids
end

class HabtmmContract
  include Mongoid::Document

  has_and_belongs_to_many :signatures, class_name: 'HabtmmSignature'

  field :item, type: :string
end

class HabtmmSignature
  include Mongoid::Document

  has_and_belongs_to_many :contracts, class_name: 'HabtmmContract'

  field :name, type: :string
  field :year, type: :integer
end

class HabtmmTicket
  include Mongoid::Document
end

class HabtmmPerson
  include Mongoid::Document

  has_and_belongs_to_many :tickets, class_name: 'HabtmmTicket'
end

class HabtmmTrainer
  include Mongoid::Document

  field :name, type: :string

  has_and_belongs_to_many :animals, inverse_of: :trainers, class_name: 'HabtmmAnimal', scope: :reptile
end

class HabtmmAnimal
  include Mongoid::Document

  field :taxonomy, type: :string

  scope :reptile, -> { where(taxonomy: 'reptile') }

  has_and_belongs_to_many :trainers, inverse_of: :animals, class_name: 'HabtmmTrainer', scope: -> { where(name: 'Dave') }
end
