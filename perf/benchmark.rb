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
  references_and_referenced_in_many :preferences, :validate => false

  index [[ "_id", Mongo::ASCENDING ], [ "addresses._id", Mongo::ASCENDING ]]
  index [[ "_id", Mongo::ASCENDING ], [ "name._id", Mongo::ASCENDING ]]
  index "preference_ids"
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

  index "person_id"
end

class Game
  include Mongoid::Document

  field :name, :type => String
  referenced_in :person

  index "person_id"
end

class Preference
  include Mongoid::Document

  field :name, :type => String
  references_and_referenced_in_many :people

  index "person_ids"
end

puts "Creating indexes..."

[ Person, Post, Game, Preference ].each(&:create_indexes)

puts "Starting benchmark..."

Benchmark.bm do |bm|

  puts "\n[ Root Document Benchmarks ]"

  [ 1000, 10000, 100000, 1000000 ].each do |i|

    Mongoid.unit_of_work do

      puts "[ #{i} ]"

      bm.report("#create           ") do
        i.times do |n|
          Person.create(:birth_date => Date.new(1970, 1, 1))
        end
      end

      bm.report("#each             ") do
        Person.all.each { |person| person.birth_date }
      end

      bm.report("#save             ") do
        Person.all.each do |person|
          person.title = "Testing"
          person.save
        end
      end

      bm.report("#update_attribute ") do
        Person.all.each { |person| person.update_attribute(:title, "Updated") }
      end

      Person.delete_all
    end
  end

  person = Person.create(:birth_date => Date.new(1970, 1, 1))

  puts "\n[ Embedded 1-n Benchmarks ]"

  [ 1000, 10000 ].each do |i|

    Mongoid.unit_of_work do

      puts "[ #{i} ]"

      bm.report("#build            ") do
        i.times do |n|
          person.addresses.build(
            :street => "Wienerstr. #{n}",
            :city => "Berlin",
            :post_code => "10999"
          )
        end
      end

      bm.report("#clear            ") do
        person.addresses.clear
      end

      bm.report("#create           ") do
        i.times do |n|
          person.addresses.create(
            :street => "Wienerstr. #{n}",
            :city => "Berlin",
            :post_code => "10999"
          )
        end
      end

      bm.report("#count            ") do
        person.addresses.count
      end

      bm.report("#delete_all       ") do
        person.addresses.delete_all
      end

      bm.report("#push             ") do
        i.times do |n|
          person.addresses.push(
            Address.new(
              :street => "Wienerstr. #{n}",
              :city => "Berlin",
              :post_code => "10999"
            )
          )
        end
      end

      bm.report("#save             ") do
        person.addresses.each do |address|
          address.address_type = "Work"
          address.save
        end
      end

      bm.report("#update_attribute ") do
        person.addresses.each do |address|
          address.update_attribute(:address_type, "Home")
        end
      end

      address = person.addresses.last

      bm.report("#find             ") do
        person.addresses.find(address.id)
      end

      bm.report("#delete           ") do
        person.addresses.delete(address)
      end

      person.addresses.delete_all
    end
  end

  puts "\n[ Embedded 1-1 Benchmarks ]"

  [ 1000, 10000 ].each do |i|

    Mongoid.unit_of_work do

      puts "[ #{i} ]"

      bm.report("#relation=        ") do
        i.times do |n|
          person.name = Name.new(:given => "Name #{n}")
        end
      end
    end
  end

  puts "\n[ Referenced 1-n Benchmarks ]"

  [ 1000, 10000, 100000 ].each do |i|

    Mongoid.unit_of_work do

      puts "[ #{i} ]"

      bm.report("#build            ") do
        i.times do |n|
          person.posts.build(:title => "Posting #{n}")
        end
      end

      bm.report("#clear            ") do
        person.posts.clear
      end

      bm.report("#create           ") do
        i.times do |n|
          person.posts.create(:title => "Posting #{n}")
        end
      end

      bm.report("#count            ") do
        person.posts.count
      end

      bm.report("#delete_all       ") do
        person.posts.delete_all
      end

      bm.report("#push             ") do
        i.times do |n|
          person.posts.push(Post.new(:title => "Posting #{n}"))
        end
      end

      bm.report("#save             ") do
        person.posts.each do |post|
          post.content = "Test"
          post.save
        end
      end

      bm.report("#update_attribute ") do
        person.posts.each do |post|
          post.update_attribute(:content, "Testing")
        end
      end

      post = person.posts.last

      bm.report("#find             ") do
        person.posts.find(post.id)
      end

      bm.report("#delete           ") do
        person.posts.delete(post)
      end

      person.posts.delete_all
    end
  end

  puts "\n[ Referenced 1-1 Benchmarks ]"

  [ 1000, 10000, 100000 ].each do |i|

    Mongoid.unit_of_work do

      puts "[ #{i} ]"

      bm.report("#relation=        ") do
        i.times do |n|
          person.name = Game.new(:name => "Final Fantasy #{n}")
        end
      end
    end
  end

  puts "\n[ Referenced n-n Benchmarks ]"

  [ 1000, 10000 ].each do |i|

    Mongoid.unit_of_work do

      puts "[ #{i} ]"

      bm.report("#build            ") do
        i.times do |n|
          person.preferences.build(:name => "Preference #{n}")
        end
      end

      bm.report("#clear            ") do
        person.preferences.clear
      end

      bm.report("#create           ") do
        i.times do |n|
          person.preferences.create(:name => "Preference #{n}")
        end
      end

      bm.report("#count            ") do
        person.preferences.count
      end

      bm.report("#delete_all       ") do
        person.preferences.delete_all
      end

      bm.report("#push             ") do
        i.times do |n|
          person.preferences.push(Preference.new(:name => "Preference #{n}"))
        end
      end

      bm.report("#save             ") do
        person.preferences.each do |preference|
          preference.name = "Test"
          preference.save
        end
      end

      bm.report("#update_attribute ") do
        person.preferences.each do |preference|
          preference.update_attribute(:name, "Testing")
        end
      end

      preference = person.preferences.last

      bm.report("#find             ") do
        person.preferences.find(preference.id)
      end

      bm.report("#delete           ") do
        person.preferences.delete(preference)
      end

      person.preferences.delete_all
    end
  end
end
