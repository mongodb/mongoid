require "benchmark"
require "mongoid"

Mongoid.configure do |config|
  config.master = Mongo::Connection.new.db("mongoid_perf_test")
end

Mongoid.master.collections.select {|c| c.name !~ /system/ }.each(&:drop)

class Person
  include Mongoid::Document
  include Mongoid::Timestamps
  field :birth_date, :type => Date
  field :title, :type => String

  embeds_one :name, :validate => false
  embeds_many :addresses, :validate => false
  embeds_many :phones, :validate => false

  references_many :posts, :validate => false
  references_one :game, :validate => false
  references_and_referenced_in_many :preferences
end

class Name
  include Mongoid::Document
  field :given, :type => String
  field :family, :type => String
  field :middle, :type => String
  embedded_in :person
end

class Address
  include Mongoid::Document
  field :street, :type => String
  field :city, :type => String
  field :state, :type => String
  field :post_code, :type => String
  field :address_type, :type => String
  embedded_in :person
end

class Phone
  include Mongoid::Document
  field :country_code, :type => Integer
  field :number, :type => String
  field :phone_type, :type => String
  embedded_in :person
end

class Post
  include Mongoid::Document
  field :title, :type => String
  field :content, :type => String
  referenced_in :person
end

class Game
  include Mongoid::Document
  field :name, :type => String
  referenced_in :person
end

class Preference
  include Mongoid::Document
  field :name, :type => String
  references_and_referenced_in_many :people
end

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
    Person.all.each { |person| person.birth_date }
  end
  bm.report("Updating The Root Document 10k Times") do
    person = Person.first
    10000.times do |n|
      person.title = "#{n}"
      person.save
    end
  end
  bm.report("Updating An Embedded Document 10k Times") do
    person = Person.first
    10000.times do |n|
      person.name.family = "Kirk #{n}"
      person.name.save
    end
  end
  bm.report("Appending A New Embedded Document 10k Times") do
    person = Person.first
    10000.times do |n|
      person.addresses.clear
      address = Address.new(
        :street => "#{n} Market St.",
        :city => "San Francisco",
        :state => "CA",
        :post_code => "94123",
        :type => "Home"
      )
      person.addresses << address
    end
  end
  bm.report("Appending A New Rel 1-N Document 10k Times") do
    person = Person.first
    10000.times do |n|
      person.posts.clear
      post = Post.new(:title => "Post #{n}", :content => "Testing")
      person.posts << post
    end
  end
  bm.report("Appending A New Rel N-N Document 10k Times") do
    person = Person.first
    10000.times do |n|
      person.preferences.clear
      preference = Preference.new(:name => "Preference #{n}")
      person.preferences << preference
    end
  end
  bm.report("Appending A New Rel 1-1 Document 10k Times") do
    person = Person.first
    10000.times do |n|
      game = Game.new(:name => "Final Fantasy #{n}")
      person.game = game
    end
  end
end

# 1.2.15:                                           User     System      Total        Real
#
# Saving 10k New Documents                    25.440000   0.670000  26.110000 ( 29.945368)
# Querying & Iterating 10k Documents           2.440000   0.110000   2.550000 (  2.736474)
# Updating The Root Document 10k Times        13.950000   0.600000  14.550000 ( 16.961482)
# Updating An Embedded Document 10k Times     16.810000   0.610000  17.420000 ( 19.051299)
# Appending A New Embedded Document 10k Times 17.330000   0.650000  17.980000 ( 19.706136)
# ---------------------------------------------------------------------------------------
# 2.0.0.beta1:
#
# Saving 10k New Documents                    24.500000   0.440000  24.940000 ( 25.091105)
# Querying & Iterating 10k Documents           3.140000   0.110000   3.250000 (  3.275101)
# Updating The Root Document 10k Times        13.500000   0.480000  13.980000 ( 15.101454)
# Updating An Embedded Document 10k Times     16.580000   0.570000  17.150000 ( 18.471384)
# Appending A New Embedded Document 10k Times 16.720000   0.560000  17.280000 ( 18.491286)
# ---------------------------------------------------------------------------------------
# 2.0.0.beta2:
#
# Saving 10k New Documents                    23.700000   0.380000  24.080000 ( 24.171105)
# Querying & Iterating 10k Documents           2.980000   0.100000   3.080000 (  3.090209)
# Updating The Root Document 10k Times        11.550000   0.440000  11.990000 ( 13.047147)
# Updating An Embedded Document 10k Times     12.250000   0.500000  12.750000 ( 13.786223)
# Appending A New Embedded Document 10k Times 12.320000   0.510000  12.830000 ( 14.392891)
# ---------------------------------------------------------------------------------------
# 2.0.0.beta3:
#
# Saving 10k New Documents                    23.890000   0.380000  24.270000 ( 24.332954)
# Querying & Iterating 10k Documents           2.980000   0.100000   3.080000 (  3.105810)
# Updating The Root Document 10k Times         4.870000   0.110000   4.980000 (  4.976892)
# Updating An Embedded Document 10k Times      3.430000   0.100000   3.530000 (  3.536181)
# Appending A New Embedded Document 10k Times  7.030000   0.220000   7.250000 ( 12.238345)
# ---------------------------------------------------------------------------------------
# 2.0.0.beta9:
#
# Saving 10k New Documents                    21.040000   0.350000  21.390000 ( 21.426144)
# Querying & Iterating 10k Documents           3.590000   0.110000   3.700000 (  3.732166)
# Updating The Root Document 10k Times         5.430000   0.130000   5.560000 (  5.568188)
# Updating An Embedded Document 10k Times      3.630000   0.110000   3.740000 (  3.765507)
# Appending A New Embedded Document 10k Times  9.550000   0.270000   9.820000 ( 13.363242)
# ---------------------------------------------------------------------------------------
# 2.0.0.beta11
#
# Saving 10k New Documents                    16.140000   0.300000  16.440000 ( 16.439016)
# Querying & Iterating 10k Documents           3.030000   0.080000   3.110000 (  3.128215)
# Updating The Root Document 10k Times         5.610000   0.180000   5.790000 (  5.785066)
# Updating An Embedded Document 10k Times      4.520000   0.150000   4.670000 (  4.669489)
# Appending A New Embedded Document 10k Times  7.140000   0.260000   7.400000 (  7.395471)
# ---------------------------------------------------------------------------------------
# 2.0.0.beta.15
#
# Saving 10k New Documents                    14.450000   0.360000  14.810000 ( 14.797150)
# Querying & Iterating 10k Documents           1.150000   0.070000   1.220000 (  1.234555)
# Updating The Root Document 10k Times         3.040000   0.160000   3.200000 (  3.195466)
# Updating An Embedded Document 10k Times      2.550000   0.130000   2.680000 (  2.668367)
# Appending A New Embedded Document 10k Times  5.080000   0.240000   5.320000 (  5.327933)
# ---------------------------------------------------------------------------------------
# 2.0.0.beta.20 (1.9.2)
#
# Saving 10k New Documents                    19.530000   0.270000  19.800000 ( 19.778292)
# Querying & Iterating 10k Documents           1.150000   0.060000   1.210000 (  1.219632)
# Updating The Root Document 10k Times         3.270000   0.120000   3.390000 (  3.387370)
# Updating An Embedded Document 10k Times      2.680000   0.110000   2.790000 (  2.790347)
# Appending A New Embedded Document 10k Times  7.230000   0.240000   7.470000 (  7.458122)
#
# ---------------------------------------------------------------------------------------
# 2.0.0.rc.1 (1.9.2)

# Saving 10k New Documents                    12.230000   0.130000  12.360000 ( 12.345798)
# Querying & Iterating 10k Documents           0.560000   0.050000   0.610000 (  0.615744)
# Updating The Root Document 10k Times         3.430000   0.090000   3.520000 (  3.520051)
# Updating An Embedded Document 10k Times      1.810000   0.090000   1.900000 (  1.900921)
# Appending A New Embedded Document 10k Times  6.950000   0.230000   7.180000 (  7.175059)
#
# ---------------------------------------------------------------------------------------
# 2.0.0.rc.4 (1.9.2)
#
# Saving 10k New Documents                    11.200000   0.200000  11.400000 ( 11.389380)
# Querying & Iterating 10k Documents           0.520000   0.040000   0.560000 (  0.559999)
# Updating The Root Document 10k Times         3.810000   0.110000   3.920000 (  3.918684)
# Updating An Embedded Document 10k Times      1.950000   0.100000   2.050000 (  2.048782)
# Appending A New Embedded Document 10k Times  5.460000   0.230000   5.690000 (  5.693213)
# Appending A New Rel 1-N Document 10k Times   4.780000   0.220000   5.000000 (  4.990632)
# Appending A New Rel N-N Document 10k Times   4.970000   0.230000   5.200000 (  5.192329)
# Appending A New Rel 1-1 Document 10k Times   2.740000   0.100000   2.840000 (  2.836493)
