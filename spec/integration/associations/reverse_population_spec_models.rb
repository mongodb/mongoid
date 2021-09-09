# frozen_string_literal: true

module ReversePopulationSpec
  class Company
    include Mongoid::Document

    has_many :emails, class_name: 'ReversePopulationSpec::Email'
    has_one :founder, class_name: 'ReversePopulationSpec::Founder'
  end

  class Email
    include Mongoid::Document

    belongs_to :company, class_name: 'ReversePopulationSpec::Company'
  end

  class Founder
    include Mongoid::Document

    belongs_to :company, class_name: 'ReversePopulationSpec::Company'
  end

  class Animal
    include Mongoid::Document

    field :a, type: String
    has_and_belongs_to_many :zoos, class_name: 'ReversePopulationSpec::Zoo'
  end

  class Zoo
    include Mongoid::Document

    field :z, type: String
    has_and_belongs_to_many :animals, class_name: 'ReversePopulationSpec::Animal'
  end
end
