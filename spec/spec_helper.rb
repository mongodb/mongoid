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
  fields \
    :title,
    :terms,
    :age
  has_many :addresses
  has_one :name
end

class Address < Mongoid::Document
  fields \
    :street,
    :city,
    :state,
    :post_code
  belongs_to :person
end

class Name < Mongoid::Document
  fields \
    :first_name,
    :last_name
  belongs_to :person
end

class Tester < Mongoid::Document
  has_timestamps
end

class Decorated
  include Mongoid::Associations::Decorator

  def initialize(doc)
    @document = doc
  end
end
