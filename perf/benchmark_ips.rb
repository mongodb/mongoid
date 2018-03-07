require "benchmark/ips"
require "mongoid"
require "./perf/models"
require './perf/gc_suite'

Mongoid.connect_to("mongoid_perf_test")
Mongo::Logger.logger.level = ::Logger::FATAL
Mongoid.purge!

puts "Creating indexes..."

[ Person, Post, Game, Preference ].each(&:create_indexes)

puts "Starting benchmark..."

suite = GCSuite.new

def person
  @person ||= Person.last
end

def person_post_id
  @person_post_id ||= person_post.id
end


def preference
  @preference ||= person.preferences.last
end

def preference_id
  @preference_id ||= preference.id
end

def address
  @address ||= person.addresses.last
end

def address_id
  @address_id ||= address.id
end

def person_post
  @person_post ||= person.posts.last
end

def addresses
  [].tap do |res|
    10000.times do |n|
      res << Address.new(
        :street => "Wienerstr. #{n}",
        :city => "Berlin",
        :post_code => "10999"
      )
    end
  end
end

def posts
  [].tap do |_posts|
    10000.times do |n|
      _posts << Post.new(:title => "Posting #{n}")
    end
  end
end

def preferences
  [].tap do |_preferences|
    10000.times do |n|
      _preferences << Preference.new(:name => "Preference #{n}")
    end
  end
end

Benchmark.ips do |bm|
  bm.config(:time => 5, :warmup => 2, :suite => GCSuite.new)
  puts "\n[ Root Document Benchmarks ]"

  bm.report("#new") do
    Person.new
  end

  bm.report("#create") do
    Person.create(:birth_date => Date.new(1970, 1, 1))
  end

  bm.report("#each") do
    Person.all.each { |_person| _person.birth_date }
  end

  bm.report("#find") do
    Person.find(Person.first.id)
  end

  bm.report("#save") do
    Person.all.each do |_person|
      _person.title = "Testing"
      _person.save
    end
  end

  bm.report("#update_attribute") do
    Person.all.each { |_person| _person.update_attribute(:title, "Updated") }
  end

  puts "\n[ Embedded 1-n Benchmarks ]"

  bm.report("#build") do |n|
    person.addresses.build(
      :street => "Wienerstr. #{n}",
      :city => "Berlin",
      :post_code => "10999"
    )
  end

  bm.report("#clear") do
    person.addresses.clear
  end

  bm.report("#create") do |n|
    person.addresses.create(
      :street => "Wienerstr. #{n}",
      :city => "Berlin",
      :post_code => "10999"
    )
  end

  bm.report("#count") do
    person.addresses.count
  end

  bm.report("#delete_all") do
    person.addresses.delete_all
  end

  # person.addresses.clear

  bm.report("#push") do |n|
    person.addresses.push(
      Address.new(
        :street => "Wienerstr. #{n}",
        :city => "Berlin",
        :post_code => "10999"
      )
    )
  end

  # WARN: using global addresses method.
  bm.report("#push (batch)") do |n|
    person.addresses.concat(addresses)
  end

  bm.report("#each") do
    person.addresses.each do |address|
      address.street
    end
  end

  # IMPROVEME:
  # Don't know for now how to isolate variable to make test more isolated and clean.
  bm.report("#find") do |n|
    person.addresses.find(address_id)
  end

  bm.report("#delete") do
    person.addresses.delete(address)
  end

  puts "\n[ Embedded 1-1 Benchmarks ]"

  bm.report("#relation=") do |n|
    person.name = Name.new(:given => "Name #{n}")
  end

  puts "\n[ Referenced 1-n Benchmarks ]"
  bm.report("#build") do |n|
    person.posts.build(:title => "Posting #{n}")
  end

  bm.report("#clear") do
    person.posts.clear
  end

  bm.report("#create") do |n|
    person.posts.create(:title => "Posting #{n}")
  end

  bm.report("#count") do
    person.posts.count
  end

  bm.report("#delete_all") do
    person.posts.delete_all
  end

  bm.report("#push") do |n|
    person.posts.push(Post.new(:title => "Posting #{n}"))
  end

  # REVIEWME:
  # Do we need actually delete posts before next case?

  # WARN: Global method.
  bm.report("#push (batch)") do |n|
    person.posts.concat(posts)
  end

  bm.report("#each") do
    person.posts.each do |post|
      post.title
    end
  end

  # IMPROVEME:
  # the same problem here as was metioned above.
  bm.report("#find") do
    person.posts.find(person_post_id)
  end

  bm.report("#delete") do
    person.posts.delete(person_post)
  end

  puts "\n[ Referenced 1-1 Benchmarks ]"

  bm.report("#relation=") do |n|
    person.game = Game.new(:name => "Final Fantasy #{n}")
  end

  puts "\n[ Referenced n-n Benchmarks ]"

  bm.report("#build") do |n|
    person.preferences.build(:name => "Preference #{n}")
  end

  bm.report("#clear") do
    person.preferences.clear
  end

  bm.report("#count") do
    person.preferences.count
  end

  bm.report("#delete_all") do
    person.preferences.delete_all
  end

  bm.report("#push") do |n|
    person.preferences.push(Preference.new(:name => "Preference #{n}"))
  end

  bm.report("#push (batch)") do |n|
    person.preferences.concat(preferences)
  end

  bm.report("#each") do
    person.preferences.each do |_preference|
      _preference.name
    end
  end

  bm.report("#find") do
    person.preferences.find(preference_id)
  end

  bm.report("#delete") do
    person.preferences.delete(preference)
  end

  bm.report("#delete_all") do
    Person.delete_all
  end
end
