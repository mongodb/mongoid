$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require 'rubygems'

gem "mocha", "0.9.7"

require "mocha"
require "mongoloid"
require "spec"

Mongoloid.connect_to("mongoloid_test")

class Person < Mongoloid::Document
  fields :title
  has_many :addresses
  has_one :name
end

class Address < Mongoloid::Document
  fields \
    :street,
    :city,
    :state,
    :post_code
  belongs_to :person
end

class Name < Mongoloid::Document
  fields \
    :first_name,
    :last_name
  belongs_to :person
end