require "benchmark"
require "mongoid"

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

  bm.report("[ root ] Create 1 million basic new documents") do
    1000000.times do |n|
      Person.create(:birth_date => Date.new(1970, 1, 1))
    end
  end

  bm.report("[ root ] Querying and iterating 1 million documents") do
    Person.all.each { |person| person.birth_date }
  end

  bm.report("[ root ] Updating 1 million documents") do
    Person.all.each { |person| person.update_attribute(:title, "Updated") }
  end

  person = Person.first

  bm.report("[ emb:one-to-many ] Appending 1k embedded documents to a single document") do
    1000.times do |n|
      person.addresses.create(
        :street => "Wienerstr. #{n}",
        :city => "Berlin",
        :post_code => "10999"
      )
    end
  end

  bm.report("[ emb:one-to-many ] Updating 1k embedded documents") do
    person.addresses.each do |address|
      address.update_attribute(:address_type, "Home")
    end
  end

  bm.report("[ emb:one-to-many ] Deleting 1k embedded documents") do
    person.addresses.delete_all
  end

  bm.report("[ emb:one-to-one ] Changing out 1k embedded documents") do
    1000.times do |n|
      person.name = Name.new(:given => "Name #{n}")
    end
  end

  bm.report("[ ref:one-to-many ] Appending 100k referenced documents") do
    100000.times do |n|
      person.posts.create(:title => "Posting #{n}")
    end
  end

  bm.report("[ ref:one-to-many ] Updating 100k referenced documents") do
    person.posts.each do |post|
      post.update_attribute(:content, "My first post")
    end
  end

  bm.report("[ ref:one-to-many ] Deleting 100k referenced documents") do
    person.posts.delete_all
  end

  bm.report("[ ref:one-to-one ] Changing out 100k referenced documents") do
    100000.times do |n|
      person.game = Game.new(:name => "Final Fantasy #{n}")
    end
  end

  bm.report("[ ref:many-to-many ] Appending 100k referenced documents") do
    100000.times do |n|
      person.preferences.create(:name => "Setting #{n}")
    end
  end

  bm.report("[ ref:many-to-many ] Updating 100k referenced documents") do
    person.preferences.each do |preference|
      preference.update_attribute(:name, "Updated")
    end
  end

  bm.report("[ ref:many-to-many ] Deleting 100k referenced documents") do
    person.preferences.delete_all
  end
end
