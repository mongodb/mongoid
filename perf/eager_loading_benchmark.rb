$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require "rubygems"
require "benchmark"
require "mongoid"

Mongoid.configure do |config|
  config.master = Mongo::Connection.new.db("mongoid_perf_test", :logger => Logger.new($stdout, :info))
end

Mongoid.master.collection("people").drop
Mongoid.master.collection("posts").drop

class Person
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name
  references_many :posts
end

class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  field :title
  referenced_in :person
end

10000.times do |n|
  person = Person.create(:name => "Test_#{n}")
  person.posts.create(:title => "Test_#{2*n}")
  person.posts.create(:title => "Test_#{2*n+1}")
end

puts "Starting benchmark..."
Benchmark.bm do |bm|
  bm.report("Finding 10 posts with person, without eager loading") do
    Post.limit(10).each { |p| p.person.name }
  end

  bm.report("Finding 10 posts with person, with eager loading") do
    Post.limit(10).includes(:person).each { |p| p.person.name }
  end
  bm.report("Finding 50 posts with person, without eager loading") do
    Post.limit(50).each { |p| p.person.name }
  end

  bm.report("Finding 50 posts with person, with eager loading") do
    Post.limit(50).includes(:person).each { |p| p.person.name }
  end
  bm.report("Finding 100 posts with person, without eager loading") do
    Post.limit(100).each { |p| p.person.name }
  end

  bm.report("Finding 100 posts with person, with eager loading") do
    Post.limit(100).includes(:person).each { |p| p.person.name }
  end
end
