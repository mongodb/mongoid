$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require 'rubygems'

gem "mocha", ">= 0.9.8"

require "mocha"
require "mongoid"
require "spec"

connection = Mongo::Connection.new
Mongoid.database = connection.db("mongoid_test")

Spec::Runner.configure do |config|
  config.mock_with :mocha
  config.after :suite do
    Mongoid.database.collections.each(&:drop)
  end
end

class MixedDrink
  include Mongoid::Document
  field :name
end

class Person
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title
  field :terms, :type => Boolean
  field :age, :type => Integer, :default => 100
  field :dob, :type => Date
  field :mixed_drink, :type => MixedDrink
  field :employer_id
  field :lunch_time, :type => Time
  field :aliases, :type => Array
  field :map, :type => Hash
  field :score, :type => Integer
  field :blood_alcohol_content, :type => Float

  attr_reader :rescored

  has_many :addresses
  has_many :phone_numbers, :class_name => "Phone"

  has_one :name
  has_one :pet, :class_name => "Animal"

  accepts_nested_attributes_for :addresses, :reject_if => lambda { |attrs| attrs["street"].blank? }
  accepts_nested_attributes_for :name

  index :age
  index :addresses
  index :dob
  index :name
  index :title

  has_one_related :game
  has_many_related :posts

  def score_with_rescoring=(score)
    @rescored = score.to_i + 20
    self.score_without_rescoring = score
  end

  alias_method_chain :score=, :rescoring

  def update_addresses
    addresses.each do |address|
      address.street = "Updated Address"
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

class Doctor < Person
  field :specialty
end

class Employer
  def id
    "1"
  end
end

class CountryCode
  include Mongoid::Document
  field :code, :type => Integer
  key :code
  belongs_to :phone_number, :inverse_of => :country_codes
end

class Phone
  include Mongoid::Document
  field :number
  key :number
  belongs_to :person, :inverse_of => :phone_numbers
  has_one :country_code
end

class Animal
  include Mongoid::Document
  field :name
  key :name
  belongs_to :person, :inverse_of => :pet
end

class PetOwner
  include Mongoid::Document
  field :title
  has_one :pet
  has_one :address
end

class Pet
  include Mongoid::Document
  field :name
  field :weight, :type => Float, :default => 0.0
  has_many :vet_visits
  belongs_to :pet_owner, :inverse_of => :pet
end

class VetVisit
  include Mongoid::Document
  field :date, :type => Date
  belongs_to :pet, :inverse_of => :vet_visits
end

class Address
  include Mongoid::Document
  field :street
  field :city
  field :state
  field :post_code
  field :parent_title
  key :street
  has_many :locations
  belongs_to :addressable, :inverse_of => :addresses

  def set_parent=(set = false)
    self.parent_title = addressable.title if set
  end
end

class Location
  include Mongoid::Document
  field :name
  belongs_to :address, :inverse_of => :locations
end

class Name
  include Mongoid::Document
  field :first_name
  field :last_name
  field :parent_title
  key :first_name, :last_name
  belongs_to :person, :inverse_of => :name

  def set_parent=(set = false)
    self.parent_title = person.title if set
  end
end

class Comment
  include Mongoid::Document
  include Mongoid::Versioning
  include Mongoid::Timestamps
  field :text
  key :text
  validates_presence_of :text
end

class Post
  include Mongoid::Document
  include Mongoid::Versioning
  include Mongoid::Timestamps
  field :title
  belongs_to_related :person
end

class Game
  include Mongoid::Document
  field :high_score, :default => 500
  field :score, :type => Integer, :default => 0
  belongs_to_related :person
end

class Patient
  include Mongoid::Document
  store_in :inpatient
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

# Inhertiance test models:
class Canvas
  include Mongoid::Document
  field :name
  has_many :shapes
  has_one :writer

  def render
    shapes.each { |shape| render }
  end
end

class Browser < Canvas
  field :version, :type => Integer
  def render; end
end

class Firefox < Browser
  field :user_agent
  def render; end
end

class Writer
  include Mongoid::Document
  field :speed, :type => Integer, :default => 0

  belongs_to :canvas, :inverse_of => :writer

  def write; end
end

class HtmlWriter < Writer
  def write; end
end

class PdfWriter < Writer
  def write; end
end

class Shape
  include Mongoid::Document
  field :x, :type => Integer, :default => 0
  field :y, :type => Integer, :default => 0

  belongs_to :canvas, :inverse_of => :shapes

  def render; end
end

class Square < Shape
  field :width, :type => Integer, :default => 0
  field :height, :type => Integer, :default => 0
end

class Circle < Shape
  field :radius, :type => Integer, :default => 0
end

# Namespacing test models:
module Medical
  class Patient
    include Mongoid::Document
    field :name
    has_many :prescriptions, :class_name => "Medical::Prescription"
  end

  class Prescription
    include Mongoid::Document
    field :name
  end
end
