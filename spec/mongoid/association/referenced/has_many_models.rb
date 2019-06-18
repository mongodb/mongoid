# frozen_string_literal: true
# encoding: utf-8

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
