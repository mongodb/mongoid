# frozen_string_literal: true

module ForeignKeySpec
  class Company
    include Mongoid::Document

    field :c, type: String
    has_many :emails, class_name: 'ForeignKeySpec::Email',
      foreign_key: 'c_ref', primary_key: 'c'
    has_one :founder, class_name: 'ForeignKeySpec::Founder',
      foreign_key: 'c_ref', primary_key: 'c'
  end

  class Email
    include Mongoid::Document

    field :c_ref, type: String
    belongs_to :company, class_name: 'ForeignKeySpec::Company',
      foreign_key: 'c_ref', primary_key: 'c'
  end

  class Founder
    include Mongoid::Document

    field :c_ref, type: String
    belongs_to :company, class_name: 'ForeignKeySpec::Company',
      foreign_key: 'c_ref', primary_key: 'c'
  end

  class Animal
    include Mongoid::Document

    field :a, type: String
    has_and_belongs_to_many :zoos, class_name: 'ForeignKeySpec::Zoo',
      foreign_key: 'z_refs', primary_key: 'z'
  end

  class Zoo
    include Mongoid::Document

    field :z, type: String
    has_and_belongs_to_many :animals, class_name: 'ForeignKeySpec::Animal',
      foreign_key: 'a_refs', primary_key: 'a'
  end

  class ScopedCompany
    include Mongoid::Document

    field :c, type: String
    has_many :emails, class_name: 'ForeignKeySpec::ScopedEmail',
      foreign_key: 'c_ref', primary_key: 'c'
  end

  class ScopedEmail
    include Mongoid::Document

    field :c_ref, type: String
    belongs_to :company, class_name: 'ForeignKeySpec::ScopedCompany',
      foreign_key: 'c_ref', primary_key: 'c'

    field :s, type: String
    default_scope -> { where(s: 'on') }
  end
end
