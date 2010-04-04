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

puts "Starting benchmark..."

RubyProf.start

1000.times do |n|
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

result = RubyProf.stop
printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT, 0)

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
    Person.all.each { |person| person.birth_date }
  end
  bm.report("Updating The Root Document 10k Times") do
    10000.times do |n|
      person = Person.first
      person.birth_date = Date.new(1976, 1, 1)
      person.save
    end
  end
  bm.report("Updating An Embedded Document 10k Times") do
    10000.times do |n|
      person = Person.first
      person.name.family = "Kirk II"
      person.name.save
    end
  end
  bm.report("Appending A New Embedded Document 10k Times") do
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

# Start:                                           User     System      Total        Real
#
# Saving 10k New Documents                    25.440000   0.670000  26.110000 ( 29.945368)
# Querying & Iterating 10k Documents           2.440000   0.110000   2.550000 (  2.736474)
# Updating The Root Document 10k Times        13.950000   0.600000  14.550000 ( 16.961482)
# Updating An Embedded Document 10k Times     16.810000   0.610000  17.420000 ( 19.051299)
# Appending A New Embedded Document 10k Times 17.330000   0.650000  17.980000 ( 19.706136)
# ---------------------------------------------------------------------------------------
# First pass:
#
# Saving 10k New Documents                    24.500000   0.440000  24.940000 ( 25.091105)
# Querying & Iterating 10k Documents           3.140000   0.110000   3.250000 (  3.275101)
# Updating The Root Document 10k Times        13.500000   0.480000  13.980000 ( 15.101454)
# Updating An Embedded Document 10k Times     16.580000   0.570000  17.150000 ( 18.471384)
# Appending A New Embedded Document 10k Times 16.720000   0.560000  17.280000 ( 18.491286)
# ---------------------------------------------------------------------------------------
# Write in place:
#
# Saving 10k New Documents                    24.070000   0.430000  24.500000 ( 24.651677)
# Querying & Iterating 10k Documents           3.000000   0.110000   3.110000 (  3.135015)
# Updating The Root Document 10k Times        11.980000   0.470000  12.450000 ( 13.569498)
# Updating An Embedded Document 10k Times     13.230000   0.560000  13.790000 ( 14.985528)
# Appending A New Embedded Document 10k Times 13.140000   0.580000  13.720000 ( 14.937596)
# ---------------------------------------------------------------------------------------
# 2.0.0.beta2
#
# Saving 10k New Documents                    23.700000   0.380000  24.080000 ( 24.171105)
# Querying & Iterating 10k Documents           2.980000   0.100000   3.080000 (  3.090209)
# Updating The Root Document 10k Times        11.550000   0.440000  11.990000 ( 13.047147)
# Updating An Embedded Document 10k Times     12.250000   0.500000  12.750000 ( 13.786223)
# Appending A New Embedded Document 10k Times 12.320000   0.510000  12.830000 ( 14.392891)

# Mongoid.database.collection("people").drop
