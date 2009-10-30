$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require 'rubygems'

gem "mocha", "0.9.8"

require "mocha"
require "mongoid"
require "spec"

Mongoid.connect_to("mongoid_test")

Spec::Runner.configure do |config|
  config.mock_with :mocha
  Mocha::Configuration.prevent(:stubbing_non_existent_method)
end

class Person < Mongoid::Document
  include Mongoid::Timestamps
  field :title
  field :terms, :type => Boolean
  field :age, :type => Integer
  has_many :addresses
  has_many :phone_numbers, :class_name => "Phone"
  has_one :name
  has_one :pet, :class_name => "Animal"
end

class Address < Mongoid::Document
  field :street
  field :city
  field :state
  field :post_code
  key :street
  belongs_to :person
end

class Phone < Mongoid::Document
  field :number
  key :number
  belongs_to :person
  has_one :country_code
end

class CountryCode < Mongoid::Document
  field :code, :type => Integer
  key :code
  belongs_to :phone_number
end

class Animal < Mongoid::Document
  field :name
  key :name
  belongs_to :person
end

class Name < Mongoid::Document
  field :first_name
  field :last_name
  key :first_name, :last_name
  belongs_to :person
end

class Decorated
  include Mongoid::Associations::Decorator

  def initialize(doc)
    @document = doc
  end
end
