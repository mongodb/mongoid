require "benchmark"
require "mongoid"
require "./perf/models"

Mongoid.connect_to("mongoid_perf_test")

Mongoid.purge!

puts "Creating indexes..."

[ Person, Post, Game, Preference ].each(&:create_indexes)

puts "Starting benchmark..."

Benchmark.bm do |bm|

  puts "\n[ Root Document Benchmarks ]"

  [ 100000 ].each do |i|

    puts "[ #{i} ]"

    bm.report("#new              ") do
      i.times do |n|
        Person.new
      end
    end

    bm.report("#create           ") do
      i.times do |n|
        Person.create(:birth_date => Date.new(1970, 1, 1))
      end
    end

    bm.report("#each             ") do
      Person.all.each { |person| person.birth_date }
    end

    bm.report("#find             ") do
      Person.find(Person.first.id)
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

    GC.start
  end

  person = Person.create(:birth_date => Date.new(1970, 1, 1))

  puts "\n[ Embedded 1-n Benchmarks ]"

  [ 1000 ].each do |i|

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

    person.addresses.clear
    GC.start

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

    person.addresses.clear
    GC.start

    bm.report("#push (batch)     ") do
      addresses = []
      i.times do |n|
        addresses << Address.new(
            :street => "Wienerstr. #{n}",
            :city => "Berlin",
            :post_code => "10999"
          )
      end
      person.addresses.concat(addresses)
    end

    bm.report("#each             ") do
      person.addresses.each do |address|
        address.street
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

  GC.start

  puts "\n[ Embedded 1-1 Benchmarks ]"

  [ 1000 ].each do |i|

    puts "[ #{i} ]"

    bm.report("#relation=        ") do
      i.times do |n|
        person.name = Name.new(:given => "Name #{n}")
      end
    end
  end

  GC.start

  puts "\n[ Referenced 1-n Benchmarks ]"

  [ 100000 ].each do |i|

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

    GC.start

    bm.report("#count            ") do
      person.posts.count
    end

    bm.report("#delete_all       ") do
      person.posts.delete_all
    end

    Post.delete_all
    GC.start

    bm.report("#push             ") do
      i.times do |n|
        person.posts.push(Post.new(:title => "Posting #{n}"))
      end
    end

    person.posts.delete_all
    GC.start

    bm.report("#push (batch)     ") do
      posts = []
      i.times do |n|
        posts << Post.new(:title => "Posting #{n}")
      end
      person.posts.concat(posts)
    end

    bm.report("#each             ") do
      person.posts.each do |post|
        post.title
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
    GC.start
  end

  Post.delete_all

  puts "\n[ Referenced 1-1 Benchmarks ]"

  [ 100000 ].each do |i|

    puts "[ #{i} ]"

    bm.report("#relation=        ") do
      i.times do |n|
        person.game = Game.new(:name => "Final Fantasy #{n}")
      end
    end
  end

  Game.delete_all
  GC.start

  puts "\n[ Referenced n-n Benchmarks ]"

  [ 10000 ].each do |i|

    puts "[ #{i} ]"

    GC.disable

    bm.report("#build            ") do
      i.times do |n|
        person.preferences.build(:name => "Preference #{n}")
      end
    end

    GC.enable
    GC.start

    bm.report("#clear            ") do
      person.preferences.clear
    end

    bm.report("#count            ") do
      person.preferences.count
    end

    bm.report("#delete_all       ") do
      person.preferences.delete_all
    end

    person.preferences.delete_all
    GC.start

    bm.report("#push             ") do
      i.times do |n|
        person.preferences.push(Preference.new(:name => "Preference #{n}"))
      end
    end

    person.preferences.delete_all
    GC.start

    bm.report("#push (batch)     ") do
      preferences = []
      i.times do |n|
        preferences << Preference.new(:name => "Preference #{n}")
      end
      person.preferences.concat(preferences)
    end

    bm.report("#each             ") do
      person.preferences.each do |preference|
        preference.name
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
    GC.start
  end

  Person.delete_all
  Preference.delete_all

  [ 10000 ].each do |i|

    GC.start

    i.times do |n|

      Person.create(:title => "#{n}").tap do |person|
        person.posts.create(:title => "#{n}")
        person.preferences.create(:name => "#{n}")
      end
    end

    puts "\n[ Iterate with association load 1-1 ]"

    bm.report("#each [ normal ] ") do
      Post.all.each do |post|
        post.person.title
      end
    end

    bm.report("#each [ eager ]  ") do
      Post.includes(:person).each do |post|
        post.person.title
      end
    end

    puts "\n[ Iterate with association load 1-n ]"

    bm.report("#each [ normal ] ") do
      Person.all.each do |person|
        person.posts.each { |post| post.title }
      end
    end

    bm.report("#each [ eager ]  ") do
      Person.includes(:posts).each do |person|
        person.posts.each { |post| post.title }
      end
    end

    puts "\n[ Iterate with association load n-n ]"

    bm.report("#each [ normal ] ") do
      Person.all.each do |person|
        person.preferences.each { |preference| preference.name }
      end
    end

    bm.report("#each [ eager ]  ") do
      Person.includes(:preferences).each do |person|
        person.preferences.each { |preference| preference.name }
      end
    end
  end
end
