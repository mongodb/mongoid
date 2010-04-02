require "rubygems"
require "ruby-prof"
require "benchmark"

require "mongoid"

Mongoid.configure do |config|
  config.persist_in_safe_mode = false
  config.master = Mongo::Connection.new.db("mongoid_perf_test")
end

Mongoid.master.collection("people").drop

class Person
  include Mongoid::Document
  include Mongoid::Timestamps
  field :birth_date, :type => Date
  embeds_one :name
  embeds_many :addresses
  embeds_many :phones
end

class Name
  include Mongoid::Document
  field :given
  field :family
  field :middle
  embedded_in :person, :inverse_of => :name
end

class Address
  include Mongoid::Document
  field :street
  field :city
  field :state
  field :post_code
  field :address_type
  embedded_in :person, :inverse_of => :addresses
end

class Phone
  include Mongoid::Document
  field :country_code, :type => Integer
  field :number
  field :phone_type
  embedded_in :person, :inverse_of => :phones
end

# RubyProf.start

puts "Starting benchmark..."

Benchmark.bm do |bm|
  bm.report("Saving 10k New Documents") do
    10000.times do |n|
      person = Person.new(:birth_date => Date.new(1970, 1, 1))
      name = Name.new(:given => "James", :family => "Kirk", :middle => "Tiberius")
      address = Address.new(
        :street => "1 Starfleet Command Way",
        :city => "San Francisco",
        :state => "CA",
        :post_code => "94133",
        :type => "Work"
      )
      phone = Phone.new(:country_code => 1, :number => "415-555-1212", :type => "Mobile")
      person.name = name
      person.addresses << address
      person.phones << phone
      person.save
    end
  end
  bm.report("Querying & Iterating 10k Documents") do
    Person.all.each { |person| "" }
  end
  bm.report("Updating The Root Dcoument 10k Times") do
    10000.times do |n|
      person = Person.first
      person.birth_date = Date.new(1976, 1, 1)
      person.save
    end
  end
  bm.report("Updating An Embedded Dcoument 10k Times") do
    10000.times do |n|
      person = Person.first
      person.name.family = "Kirk II"
      person.name.save
    end
  end
  bm.report("Appending A New Embedded Dcoument 10k Times") do
    10000.times do |n|
      person = Person.first
      address = Address.new(
        :street => "1 Market St.",
        :city => "San Francisco",
        :state => "CA",
        :post_code => "94123",
        :type => "Home"
      )
      person.addresses << address
      address.save
    end
  end
end

# Before internal switch:
#
# Saving 10k New Documents                    25.440000   0.670000  26.110000 ( 29.945368)
# Querying & Iterating 10k Documents           2.440000   0.110000   2.550000 (  2.736474)
# Updating The Root Dcoument 10k Times        13.950000   0.600000  14.550000 ( 16.961482)
# Updating An Embedded Dcoument 10k Times     16.810000   0.610000  17.420000 ( 19.051299)
# Appending A New Embedded Dcoument 10k Times 17.330000   0.650000  17.980000 ( 19.706136)

# result = RubyProf.stop
# printer = RubyProf::FlatPrinter.new(result)
# printer.print(STDOUT, 0)

# Mongoid.database.collection("people").drop
