$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require 'rubygems'

gem "mocha", "0.9.8"

require "mocha"
require "mongoid"
require "spec"

connection = Mongo::Connection.new
Mongoid.database = connection.db("mongoid_test")

Spec::Runner.configure do |config|
  config.mock_with :mocha
  Mocha::Configuration.prevent(:stubbing_non_existent_method)
end

class MixedDrink < Mongoid::Document
  field :name
end

class Person < Mongoid::Document
  include Mongoid::Timestamps

  field :title
  field :terms, :type => Boolean
  field :age, :type => Integer, :default => 100
  field :dob, :type => Date
  field :mixed_drink, :type => MixedDrink
  field :employer_id
  field :lunch_time, :type => Time

  has_many :addresses
  has_many :phone_numbers, :class_name => "Phone"

  has_one :name
  has_one :pet, :class_name => "Animal"

  index :title
  index :dob
  index :addresses
  index :name

  relates_to_one :game
  relates_to_many :posts

  def update_addresses
    addresses.each_with_index do |address, i|
      address.street = "Updated #{i}"
    end
  end

  def employer=(emp)
    self.employer_id = emp.id
  end

  class << self
    def accepted
      criteria.where(:terms => true)
    end
    def knight
      criteria.where(:title => "Sir")
    end
    def old
      criteria.where(:age => { "$gt" => 50 })
    end
  end

end

class Employer
  def id
    "1"
  end
end

class CountryCode < Mongoid::Document
  field :code, :type => Integer
  key :code
  belongs_to :phone_number, :inverse_of => :country_codes
end

class Phone < Mongoid::Document
  field :number
  key :number
  belongs_to :person, :inverse_of => :phone_numbers
  has_one :country_code
end

class Animal < Mongoid::Document
  field :name
  key :name
  belongs_to :person, :inverse_of => :pet
end

class PetOwner < Mongoid::Document
  field :title
  has_one :pet
end

class Pet < Mongoid::Document
  field :name
  field :weight, :type => Float, :default => 0.0
  has_many :vet_visits
  belongs_to :pet_owner, :inverse_of => :pet
end

class VetVisit < Mongoid::Document
  field :date, :type => Date
  belongs_to :pet, :inverse_of => :vet_visits
end

class Address < Mongoid::Document
  field :street
  field :city
  field :state
  field :post_code
  key :street
  belongs_to :addressable, :inverse_of => :addresses
end

class Name < Mongoid::Document
  field :first_name
  field :last_name
  key :first_name, :last_name
  belongs_to :person, :inverse_of => :name
end

class Comment < Mongoid::Document
  include Mongoid::Versioning
  field :text
  key :text
end

class Post < Mongoid::Document
  include Mongoid::Versioning
  field :title
  relates_to_one :person
end

class Game < Mongoid::Document
  field :high_score, :default => 500
  field :score, :type => Integer, :default => 0
end

if RUBY_VERSION == '1.8.6'
  class Array
    alias :count :size
  end
end

class Object
  def tapp
    tap do
      puts "#{File.basename caller[2]}: #{self.inspect}"
    end
  end
end
