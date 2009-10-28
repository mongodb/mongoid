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
  has_one :name
end

class Address < Mongoid::Document
  field :street
  field :city
  field :state
  field :post_code
  key :street
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
