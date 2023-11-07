# frozen_string_literal: true

module ValidationsSpecModels
  class Company
    include Mongoid::Document
  end

  class Client
    include Mongoid::Document

    has_and_belongs_to_many :companies, class_name: 'ValidationsSpecModels::Company'
    validates :companies, presence: true
  end

  class Building
    include Mongoid::Document
    has_many :apartments, class_name: 'ValidationsSpecModels::Apartment'
    validates :apartments, presence: true
  end

  class Apartment
    include Mongoid::Document
    belongs_to :building, class_name: 'ValidationsSpecModels::Building'
  end
end
