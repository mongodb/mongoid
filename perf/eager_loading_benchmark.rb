$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require "rubygems"
require "benchmark"
require "mongoid"

Mongoid.configure do |config|
  #config.master = Mongo::Connection.new('localhost', 27018, :logger => Logger.new($stdout)).db("mongoid_perf_test")
  config.master = Mongo::Connection.new.db("mongoid_perf_test")
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
Benchmark.bm(60) do |bm|
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

  bm.report("Finding 1000 posts with person, without eager loading") do
    Post.limit(1000).each { |p| p.person.name }
  end
  bm.report("Finding 1000 posts with person, with eager loading") do
    Post.limit(1000).includes(:person).each { |p| p.person.name }
  end
end

#                                                                  user     system      total        real
#Finding 10 posts with person, without eager loading           0.000000   0.000000   0.000000 (  0.004790)
#Finding 10 posts with person, with eager loading              0.010000   0.000000   0.010000 (  0.002065)
#Finding 50 posts with person, without eager loading           0.010000   0.000000   0.010000 (  0.021131)
#Finding 50 posts with person, with eager loading              0.010000   0.000000   0.010000 (  0.007007)
#Finding 100 posts with person, without eager loading          0.050000   0.010000   0.060000 (  0.060699)
#Finding 100 posts with person, with eager loading             0.010000   0.000000   0.010000 (  0.014336)
#Finding 1000 posts with person, without eager loading         0.470000   0.020000   0.490000 (  0.549790)
#Finding 1000 posts with person, with eager loading            0.170000   0.010000   0.180000 (  0.184104)

