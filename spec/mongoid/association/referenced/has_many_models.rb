# frozen_string_literal: true
# encoding: utf-8

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

class HmmSchool
  include Mongoid::Document

  has_many :students, class_name: 'HmmStudent'

  field :district, type: String
  field :team, type: String
end

class HmmStudent
  include Mongoid::Document

  belongs_to :school, class_name: 'HmmSchool'

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
