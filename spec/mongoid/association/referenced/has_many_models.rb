# frozen_string_literal: true

class HmmCompany
  include Mongoid::Document

  field :p, type: Integer
  has_many :emails, primary_key: :p, foreign_key: :f, class_name: 'HmmEmail'

  # The addresses are added with different dependency mechanisms in tests:
  #has_many :addresses, class_name: 'HmmAddress', dependent: :destroy
end

class HmmEmail
  include Mongoid::Document

  field :f, type: Integer
  belongs_to :company, primary_key: :p, foreign_key: :f, class_name: 'HmmCompany'
end

class HmmAddress
  include Mongoid::Document

  belongs_to :company, class_name: 'HmmCompany'
end

class HmmOwner
  include Mongoid::Document

  has_many :pets, class_name: 'HmmPet', inverse_of: :current_owner

  field :name, type: String
end

class HmmPet
  include Mongoid::Document

  belongs_to :current_owner, class_name: 'HmmOwner', inverse_of: :pets, optional: true
  belongs_to :previous_owner, class_name: 'HmmOwner', inverse_of: nil, optional: true

  field :name, type: String
end

class HmmSchool
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :students, class_name: 'HmmStudent'

  field :district, type: String
  field :team, type: String
end

class HmmStudent
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :school, class_name: 'HmmSchool', touch: true

  field :name, type: String
  field :grade, type: Integer, default: 3
end

class HmmTicket
  include Mongoid::Document

  belongs_to :person
end

class HmmBus
  include Mongoid::Document

  has_many :seats, class_name: 'HmmBusSeat'
end

class HmmBusSeat
  include Mongoid::Document

  # No belongs_to :bus
end

class HmmTrainer
  include Mongoid::Document

  field :name, type: String

  has_many :animals, class_name: 'HmmAnimal', scope: :reptile
end

class HmmAnimal
  include Mongoid::Document

  field :taxonomy, type: String

  scope :reptile, -> { where(taxonomy: 'reptile') }

  belongs_to :trainer, class_name: 'HmmTrainer', scope: -> { where(name: 'Dave') }
end
