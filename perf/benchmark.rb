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

# 1.87 15000  Mongoid::Attributes::InstanceMethods#write_attribute (lib/mongoid/attributes.rb:103}
# 1.65 30001  <Module::Mongoid>#configure (lib/mongoid.rb:105}
# 1.49 16000  Mongoid::Attributes::InstanceMethods#write_allowed? (lib/mongoid/attributes.rb:148}
# 0.95 17000  Mongoid::Field#default (lib/mongoid/field.rb:20}
# 0.93 18000  Mongoid::Attributes::InstanceMethods#set_allowed? (lib/mongoid/attributes.rb:132}
# 0.76  5000  Mongoid::Document::InstanceMethods#initialize (lib/mongoid/document.rb:164}
# 0.73 27000  Mongoid::Attributes::InstanceMethods#id (lib/mongoid/attributes.rb:8}
# 0.73 15000  Mongoid::Dirty::InstanceMethods#modify (lib/mongoid/dirty.rb:178}
# 0.71 18000  <Module::Mongoid>#allow_dynamic_fields ((eval):1}
# 0.69 15000  Mongoid::Field#set (lib/mongoid/field.rb:43}
# 0.53 30001  <Class::Mongoid::Config>#instance (lib/ruby/1.8/singleton.rb:99}
# 0.48  6000  <Class::Mongoid::Identity>#identify (lib/mongoid/identity.rb:23}
# 0.42  6000  <Class::Mongoid::Identity>#type (lib/mongoid/identity.rb:29}
# 0.36  5000  <Class::Mongoid::Identity>#generate_id (lib/mongoid/identity.rb:17}
# 0.34 10000  Mongoid::Observable#notify_observers (lib/mongoid/observable.rb:26}


# result = RubyProf.stop
# printer = RubyProf::FlatPrinter.new(result)
# printer.print(STDOUT, 0)

# Mongoid.database.collection("people").drop
