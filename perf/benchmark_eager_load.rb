# frozen_string_literal: true
# rubocop:todo all

require "benchmark"
require "mongoid"
require "./perf/models"

Mongoid.connect_to("mongoid_perf_test")
Mongo::Logger.logger.level = ::Logger::FATAL

Mongoid.purge!

puts "Creating indexes..."

[ Person, Post, Game, Preference, Account, Comment ].each(&:create_indexes)

puts "Setting up test data..."

# Create test data
people = []
total = 5000
print "Creating people: [#{' ' * 50}] 0%\r"

5000.times do |n|
  person = Person.create!(title: "Person #{n}")
  
  # has_many: posts
  100.times do |i|
    person.posts.create!(title: "Post #{i} for #{n}")
  end
  
  # has_one: game
  person.create_game(name: "Game for #{n}")
  
  # has_and_belongs_to_many: preferences
  100.times do |i|
    person.preferences.create!(name: "Preference #{i} for #{n}")
  end

  # Update progress bar
  progress = ((n + 1).to_f / total * 100).round
  filled = (progress / 2).round
  bar = '#' * filled + ' ' * (50 - filled)
  print "Creating people: [#{bar}] #{progress}%\r"
  
  people << person
end

puts # New line after progress bar

# Create accounts with belongs_to relationship
accounts = []
people.each_with_index do |person, n|
  account = Account.create!(name: "Account #{n}", person: person)
  
  # has_one from account
  account.create_comment(title: "Comment for account #{n}")

  if n % 1000 == 0
    puts "  Created #{n} accounts..."
  end
  
  accounts << account
end

puts "Test data created. Starting benchmarks...\n"

Benchmark.bm(30) do |bm|

  puts "\n[ belongs_to Benchmarks ]"
  
  bm.report("belongs_to: normal          ") do
    Account.all.each do |account|
      account.person.title
    end
  end
  
  bm.report("belongs_to: includes        ") do
    Account.includes(:person).each do |account|
      account.person.title
    end
  end
  
  bm.report("belongs_to: eager_load      ") do
    Account.eager_load(:person).each do |account|
      account.person.title
    end
  end

  puts "\n[ has_one Benchmarks ]"
  
  bm.report("has_one: normal             ") do
    Person.all.each do |person|
      person.game&.name
    end
  end
  
  bm.report("has_one: includes           ") do
    Person.includes(:game).each do |person|
      person.game&.name
    end
  end
  
  bm.report("has_one: eager_load         ") do
    Person.eager_load(:game).each do |person|
      person.game&.name
    end
  end

  puts "\n[ has_many Benchmarks ]"
  
  bm.report("has_many: normal            ") do
    Person.all.each do |person|
      person.posts.each { |post| post.title }
    end
  end
  
  bm.report("has_many: includes          ") do
    Person.includes(:posts).each do |person|
      person.posts.each { |post| post.title }
    end
  end
  
  bm.report("has_many: eager_load        ") do
    Person.eager_load(:posts).each do |person|
      person.posts.each { |post| post.title }
    end
  end

  puts "\n[ has_and_belongs_to_many Benchmarks ]"
  
  bm.report("habtm: normal               ") do
    Person.all.each do |person|
      person.preferences.each { |pref| pref.name }
    end
  end
  
  bm.report("habtm: includes             ") do
    Person.includes(:preferences).each do |person|
      person.preferences.each { |pref| pref.name }
    end
  end
  
  bm.report("habtm: eager_load           ") do
    Person.eager_load(:preferences).each do |person|
      person.preferences.each { |pref| pref.name }
    end
  end

  puts "\n[ Multiple Associations Benchmarks ]"
  
  bm.report("multiple: normal            ") do
    Person.all.each do |person|
      person.posts.each { |post| post.title }
      person.game&.name
      person.preferences.each { |pref| pref.name }
    end
  end
  
  bm.report("multiple: includes          ") do
    Person.includes(:posts, :game, :preferences).each do |person|
      person.posts.each { |post| post.title }
      person.game&.name
      person.preferences.each { |pref| pref.name }
    end
  end
  
  bm.report("multiple: eager_load        ") do
    Person.eager_load(:posts, :game, :preferences).each do |person|
      person.posts.each { |post| post.title }
      person.game&.name
      person.preferences.each { |pref| pref.name }
    end
  end

  puts "\n[ Nested Associations Benchmarks ]"
  
  # Add some nested data
  Person.limit(1000).each do |person|
    person.posts.limit(2).each do |post|
      2.times { |i| post.alerts.create!(message: "Alert #{i}") }
    end
  end
  
  bm.report("nested: normal              ") do
    Person.limit(1000).each do |person|
      person.posts.each do |post|
        post.alerts.each { |alert| alert.message }
      end
    end
  end
  
  bm.report("nested: includes            ") do
    Person.includes(posts: :alerts).limit(1000).each do |person|
      person.posts.each do |post|
        post.alerts.each { |alert| alert.message }
      end
    end
  end
  
  bm.report("nested: eager_load          ") do
    Person.eager_load(posts: :alerts).limit(1000).each do |person|
      person.posts.each do |post|
        post.alerts.each { |alert| alert.message }
      end
    end
  end

  puts "\n[ Query Count Comparison ]"
  
  # Simple subscriber for counting queries
  class QueryCounter
    attr_reader :count
    
    def initialize
      @count = 0
    end
    
    def started(event)
      @count += 1 if event.command_name == 'find'
    end
    
    def succeeded(event); end
    def failed(event); end
  end
  
  class AggregateCounter
    attr_reader :count
    
    def initialize
      @count = 0
    end
    
    def started(event)
      @count += 1 if event.command_name == 'find' || event.command_name == 'aggregate'
    end
    
    def succeeded(event); end
    def failed(event); end
  end
  
  # Count queries for normal
  normal_counter = QueryCounter.new
  Mongoid.client(:default).subscribe(Mongo::Monitoring::COMMAND, normal_counter)
  
  Person.limit(100).each do |person|
    person.posts.first
    person.game
  end
  
  puts "  normal: #{normal_counter.count} queries"
  
  # Count queries for includes
  includes_counter = QueryCounter.new
  Mongoid.client(:default).subscribe(Mongo::Monitoring::COMMAND, includes_counter)
  
  Person.includes(:posts, :game).limit(100).each do |person|
    person.posts.first
    person.game
  end
  
  puts "  includes: #{includes_counter.count} queries"
  
  # Count queries for eager_load
  eager_counter = AggregateCounter.new
  Mongoid.client(:default).subscribe(Mongo::Monitoring::COMMAND, eager_counter)
  
  Person.eager_load(:posts, :game).limit(100).each do |person|
    person.posts.first
    person.game
  end
  
  puts "  eager_load: #{eager_counter.count} queries"

  puts "\n[ Memory Usage Comparison ]"
  
  GC.start
  before = GC.stat(:total_allocated_objects)
  
  Person.includes(:posts, :game, :preferences).limit(1000).to_a
  
  after_includes = GC.stat(:total_allocated_objects)
  includes_objects = after_includes - before
  
  GC.start
  before = GC.stat(:total_allocated_objects)
  
  Person.eager_load(:posts, :game, :preferences).limit(1000).to_a
  
  after_eager = GC.stat(:total_allocated_objects)
  eager_objects = after_eager - before
  
  puts "  includes allocated: #{includes_objects} objects"
  puts "  eager_load allocated: #{eager_objects} objects"
  puts "  difference: #{eager_objects - includes_objects} objects"

end

puts "\nBenchmark complete!"
