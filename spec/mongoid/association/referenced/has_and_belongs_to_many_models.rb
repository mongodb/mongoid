# frozen_string_literal: true

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

  field :favorite_signature, default: ->{ contracts.first.signature_ids.first if contracts.first }

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

class HabtmmTrainer
  include Mongoid::Document

  field :name, type: String

  has_and_belongs_to_many :animals, inverse_of: :trainers, class_name: 'HabtmmAnimal', scope: :reptile
end

class HabtmmAnimal
  include Mongoid::Document

  field :taxonomy, type: String

  scope :reptile, -> { where(taxonomy: 'reptile') }

  has_and_belongs_to_many :trainers, inverse_of: :animals, class_name: 'HabtmmTrainer', scope: -> { where(name: 'Dave') }
end

class HabtmmSchool
  include Mongoid::Document
  include Mongoid::Timestamps

  has_and_belongs_to_many :students, class_name: 'HabtmmStudent'

  field :after_destroy_triggered, default: false

  accepts_nested_attributes_for :students, allow_destroy: true
end

class HabtmmStudent
  include Mongoid::Document
  include Mongoid::Timestamps

  has_and_belongs_to_many :schools, class_name: 'HabtmmSchool'

  after_destroy do |doc|
    schools.first.update_attributes!(after_destroy_triggered: true) unless schools.empty?
  end
end

