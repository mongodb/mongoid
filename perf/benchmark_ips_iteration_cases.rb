require "benchmark/ips"
require "mongoid"
require "./perf/models"
require './perf/gc_suite'

Mongoid.connect_to("mongoid_perf_test")
Mongo::Logger.logger.level = ::Logger::FATAL
Mongoid.purge!

suite = GCSuite.new

10000.times do |n|
  Person.create(:title => "#{n}").tap do |person|
    person.posts.create(:title => "#{n}")
    person.preferences.create(:name => "#{n}")
  end
end

puts "Creating indexes..."
[ Person, Post, Preference ].each(&:create_indexes)

puts "Starting benchmark..."

puts "\n[ Iterate with association load 1-1 ]"
Benchmark.ips do |bm|
  bm.config(:time => 5, :warmup => 2, :suite => suite)

  bm.report("#each [ normal ]") do
    Post.all.each do |post|
      post.person.title
    end
  end

  bm.report("#each [ eager ]") do
    Post.includes(:person).each do |post|
      post.person.title
    end
  end
  bm.compare!
end

puts "\n[ Iterate with association load 1-n ]"
Benchmark.ips do |bm|
  bm.config(:time => 5, :warmup => 2, :suite => suite)

  bm.report("#each [ normal ]") do
    Person.all.each do |person|
      person.posts.each { |post| post.title }
    end
  end

  bm.report("#each [ eager ]") do
    Person.includes(:posts).each do |person|
      person.posts.each { |post| post.title }
    end
  end
  bm.compare!
end

puts "\n[ Iterate with association load n-n ]"
Benchmark.ips do |bm|
  bm.config(:time => 5, :warmup => 2, :suite => suite)

  bm.report("#each [ normal ]") do
    Person.all.each do |person|
      person.preferences.each { |_preference| _preference.name }
    end
  end

  bm.report("#each [ eager ]") do
    Person.includes(:preferences).each do |person|
      person.preferences.each { |_preference| _preference.name }
    end
  end

  bm.compare!
end
