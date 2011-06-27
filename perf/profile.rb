require "mongoid"
require "perftools"

Mongoid.configure do |config|
  config.master = Mongo::Connection.new.db("mongoid_perf_test")
end

Mongoid.master.collections.select {|c| c.name !~ /system/ }.each(&:drop)

class Person
  include Mongoid::Document

  field :birth_date, :type => Date
  field :title, :type => String

  embeds_one :name, :validate => false
  embeds_many :addresses, :validate => false
  embeds_many :phones, :validate => false

  references_many :posts, :validate => false
  references_one :game, :validate => false
  references_and_referenced_in_many :preferences, :validate => false
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

puts "Starting profiler"

PerfTools::CpuProfiler.start("perf/mongoid_profile_insert") do
  10000.times do |n|
    Person.create(:birth_date => Date.new(1970, 1, 1))
  end
end

PerfTools::CpuProfiler.start("perf/mongoid_profile_query") do
  Person.all.each { |person| person.birth_date }
end

PerfTools::CpuProfiler.start("perf/mongoid_profile_update") do
  Person.all.each { |person| person.update_attribute(:title, "Updated") }
end
