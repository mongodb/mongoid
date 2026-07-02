# frozen_string_literal: true

require 'benchmark'
require 'mongoid'
require './perf/models'

Mongoid.connect_to('mongoid_perf_test')
Mongo::Logger.logger.level = Logger::FATAL

if ARGV.include?('keep-data')
  puts 'reusing existing data'
else
  Mongoid.purge!

  puts 'Creating indexes...'

  [ Person, Post, Game, Preference, Account, Comment, Cable, Cartridge, Alert ].each(&:create_indexes)

  puts 'Setting up test data...'

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
    bar = ('#' * filled) + (' ' * (50 - filled))
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

    puts "  Created #{n} accounts..." if n % 1000 == 0

    accounts << account
  end

  puts 'Test data created.'

  puts "\nSetting up PR #6158 scenario data..."

  # Subclass: 500 Speakers (with 5 cables each) + 500 plain Gadgets
  500.times do |n|
    speaker = Speaker.create!(name: "Speaker #{n}")
    5.times { |i| Cable.create!(label: "Cable #{n}-#{i}", speaker: speaker) }
  end
  500.times { |n| Gadget.create!(name: "Gadget #{n}") }

  # embeds_one: 1000 Computers, each with one Port referencing a Peripheral
  1000.times do |n|
    peripheral = Peripheral.create!(name: "Peripheral #{n}")
    computer = Computer.new(name: "Computer #{n}")
    computer.build_port(label: "Port #{n}", peripheral: peripheral)
    computer.save!
  end

  # embeds_many: 1000 Racks, each with 3 Slots each referencing a Peripheral
  1000.times do |n|
    rack = Rack.new(name: "Rack #{n}")
    3.times do |i|
      peripheral = Peripheral.create!(name: "Rack Peripheral #{n}-#{i}")
      rack.slots.build(label: "Slot #{n}-#{i}", peripheral: peripheral)
    end
    rack.save!
  end

  # Polymorphic: 500 Cartridges pointing at Printers + 500 pointing at Scanners
  500.times { |n| Cartridge.create!(hardware: Printer.create!(model: "Printer #{n}")) }
  500.times { |n| Cartridge.create!(hardware: Scanner.create!(model: "Scanner #{n}")) }

  # Add some nested data
  Person.limit(1000).each do |person|
    person.posts.limit(2).each do |post|
      2.times { |i| post.alerts.create!(message: "Alert #{i}") }
    end
  end

  puts "PR #6158 scenario data created. Starting benchmarks...\n"
end

Benchmark.bm(30) do |bm|
  puts "\n[ belongs_to Benchmarks ]"

  bm.report('belongs_to: normal') do
    Account.all.each do |account|
      account.person.title
    end
  end

  bm.report('belongs_to: includes') do
    Account.includes(:person).each do |account|
      account.person.title
    end
  end

  bm.report('belongs_to: eager_load') do
    Account.eager_load(:person).each do |account|
      account.person.title
    end
  end

  puts "\n[ has_one Benchmarks ]"

  bm.report('has_one: normal') do
    Person.all.each do |person|
      person.game&.name
    end
  end

  bm.report('has_one: includes') do
    Person.includes(:game).each do |person|
      person.game&.name
    end
  end

  bm.report('has_one: eager_load') do
    Person.eager_load(:game).each do |person|
      person.game&.name
    end
  end

  puts "\n[ has_many Benchmarks ]"

  bm.report('has_many: normal') do
    Person.all.each do |person|
      person.posts.each { |post| post.title }
    end
  end

  bm.report('has_many: includes') do
    Person.includes(:posts).each do |person|
      person.posts.each { |post| post.title }
    end
  end

  bm.report('has_many: eager_load') do
    Person.eager_load(:posts).each do |person|
      person.posts.each { |post| post.title }
    end
  end

  puts "\n[ has_and_belongs_to_many Benchmarks ]"

  bm.report('habtm: normal') do
    Person.all.each do |person|
      person.preferences.each { |pref| pref.name }
    end
  end

  bm.report('habtm: includes') do
    Person.includes(:preferences).each do |person|
      person.preferences.each { |pref| pref.name }
    end
  end

  bm.report('habtm: eager_load') do
    Person.eager_load(:preferences).each do |person|
      person.preferences.each { |pref| pref.name }
    end
  end

  puts "\n[ Multiple Associations Benchmarks ]"

  bm.report('multiple: normal') do
    Person.all.each do |person|
      person.posts.each { |post| post.title }
      person.game&.name
      person.preferences.each { |pref| pref.name }
    end
  end

  bm.report('multiple: includes') do
    Person.includes(:posts, :game, :preferences).each do |person|
      person.posts.each { |post| post.title }
      person.game&.name
      person.preferences.each { |pref| pref.name }
    end
  end

  bm.report('multiple: eager_load') do
    Person.eager_load(:posts, :game, :preferences).each do |person|
      person.posts.each { |post| post.title }
      person.game&.name
      person.preferences.each { |pref| pref.name }
    end
  end

  puts "\n[ Nested Associations Benchmarks ]"

  bm.report('nested: normal') do
    Person.limit(1000).each do |person|
      person.posts.each do |post|
        post.alerts.each { |alert| alert.message }
      end
    end
  end

  bm.report('nested: includes') do
    Person.includes(posts: :alerts).limit(1000).each do |person|
      person.posts.each do |post|
        post.alerts.each { |alert| alert.message }
      end
    end
  end

  bm.report('nested: eager_load') do
    Person.eager_load(posts: :alerts).limit(1000).each do |person|
      person.posts.each do |post|
        post.alerts.each { |alert| alert.message }
      end
    end
  end

  puts "\n[ Subclass Association Benchmarks ]"
  puts '  (includes raises for an association defined only on a subclass;'
  puts '   the workaround is to query the subclass directly)'

  bm.report('subclass: normal') do
    Gadget.all.each do |gadget|
      gadget.cables.each { |c| c.label } if gadget.respond_to?(:cables)
    end
  end

  bm.report('subclass: includes (Speaker)') do
    # Without eager_load, the caller must know to query through the subclass.
    Speaker.all.includes(:cables).each { |s| s.cables.each { |c| c.label } }
  end

  bm.report('subclass: eager_load (Gadget)') do
    Gadget.all.eager_load(:cables).each do |gadget|
      gadget.cables.each { |c| c.label } if gadget.respond_to?(:cables)
    end
  end

  puts "\n[ Embedded Reference (embeds_one) Benchmarks ]"
  puts '  (includes does not support preloading referenced associations'
  puts '   inside embedded documents; no includes row for this section)'

  bm.report('embedded_one: normal') do
    Computer.all.each { |c| c.port&.peripheral&.name }
  end

  bm.report('embedded_one: eager_load') do
    Computer.all.eager_load(port: :peripheral).each { |c| c.port&.peripheral&.name }
  end

  puts "\n[ Embedded Reference (embeds_many) Benchmarks ]"

  bm.report('embedded_many: normal') do
    Rack.all.each { |r| r.slots.each { |s| s.peripheral&.name } }
  end

  bm.report('embedded_many: eager_load') do
    Rack.all.eager_load(slots: :peripheral).each { |r| r.slots.each { |s| s.peripheral&.name } }
  end

  puts "\n[ Polymorphic belongs_to Benchmarks ]"

  bm.report('polymorphic: normal') do
    Cartridge.all.each { |c| c.hardware&.model }
  end

  bm.report('polymorphic: includes') do
    Cartridge.all.includes(:hardware).each { |c| c.hardware&.model }
  end

  bm.report('polymorphic: eager_load') do
    Cartridge.all.eager_load(:hardware).each { |c| c.hardware&.model }
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
      @count += 1 if %w[find aggregate].include?(event.command_name)
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
