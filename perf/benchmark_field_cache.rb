#!/usr/bin/env ruby
# frozen_string_literal: true
# rubocop:todo all

# Benchmark script to compare field access performance between master and current branch.
# This measures timing improvements from field access caching optimizations.
#
# Usage:
#   ruby perf/benchmark_field_cache.rb
#
# The script will:
#   1. Run benchmark on current branch
#   2. Switch to master and run benchmark
#   3. Switch back to original branch
#   4. Display comparison

require "tempfile"
require "fileutils"

# Save original branch
ORIGINAL_BRANCH = `git rev-parse --abbrev-ref HEAD`.strip

# Create temp benchmark script that can run on any branch
BENCHMARK_SCRIPT = <<~'RUBY'
  $LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

  require "benchmark/ips"
  require "mongoid"

  # Define models inline to work on both branches
  class Band
    include Mongoid::Document

    field :name, type: String
    field :origin, type: String
    field :tags, type: Hash
    field :genres, type: Array
    field :rating, type: Float
    field :member_count, type: Integer
    field :active, type: Mongoid::Boolean
    field :founded, type: Date
    field :updated, type: Time
    field :decibels, type: Range
  end

  class Person
    include Mongoid::Document

    field :birth_date, type: Date
    field :title, type: String

    embeds_many :addresses, validate: false
  end

  class Address
    include Mongoid::Document

    field :street, type: String
    field :city, type: String
    field :post_code, type: String
    embedded_in :person
  end

  Mongoid.connect_to("mongoid_perf_field_cache")
  Mongo::Logger.logger.level = ::Logger::FATAL

  # Configure time zone for Date handling
  Time.zone = "UTC"

  puts "Branch: #{`git rev-parse --abbrev-ref HEAD`.strip} | Commit: #{`git rev-parse --short HEAD`.strip}"

  # Check if caching config is available (current branch has it, master doesn't)
  cache_available = Mongoid::Config.respond_to?(:cache_attribute_values=)

  if cache_available
    Mongoid::Config.cache_attribute_values = true
    puts "Field caching: enabled"
  else
    puts "Field caching: not available (baseline)"
  end

  Mongoid.purge!

  # Create test data with all field types from performance_spec
  band = Band.create!(
    name: 'Test Band',
    origin: 'Test City',
    tags: { 'genre' => 'rock', 'era' => '80s' },
    genres: %w[rock metal],
    rating: 8.5,
    member_count: 4,
    active: true,
    founded: Date.current,
    updated: Time.current,
    decibels: (50..120)
  )

  # Also test with embedded documents
  person = Person.create!(
    title: "Senior Engineer",
    birth_date: Date.new(1985, 6, 15)
  )

  5.times do |n|
    person.addresses.create!(
      street: "Wienerstr. #{n}",
      city: "Berlin",
      post_code: "10999"
    )
  end

  Benchmark.ips do |x|
    x.config(time: 5, warmup: 2)

    puts "\n[ Repeated Field Access (10x per iteration) ]"
    x.report("String 10x") { 10.times { band.name } }
    x.report("Integer 10x") { 10.times { band.member_count } }
    x.report("Float 10x") { 10.times { band.rating } }
    x.report("Boolean 10x") { 10.times { band.active } }
    x.report("Date 10x") { 10.times { band.founded } }
    x.report("Time 10x") { 10.times { band.updated } }
    x.report("Hash 10x") { 10.times { band.tags } }
    x.report("Array 10x") { 10.times { band.genres } }
    x.report("Range 10x") { 10.times { band.decibels } }
    x.report("BSON::ObjectId 10x") { 10.times { band.id } }

    puts "\n[ Embedded Documents ]"
    x.report("iterate embedded (5 docs)") do
      person.addresses.each do |addr|
        addr.street
        addr.city
        addr.post_code
      end
    end

    puts "\n[ Read After Write ]"
    x.report("write then read") do
      band.name = "Modified Band"
      band.name
    end
  end
RUBY

def parse_results(text)
  results = {}
  calculating_section = text.split('Calculating -------------------------------------')[1]
  return results unless calculating_section
  
  calculating_section.scan(/^\s*(.+?)\s+([\d.]+[kM])\s+\([^)]+\)\s+i\/s/) do |name, ips|
    multiplier = ips.include?('M') ? 1_000_000 : 1_000
    value = ips.gsub(/[kM]/, '').to_f * multiplier
    results[name.strip] = value
  end
  results
end

def compare_results(current_file, master_file)
  current = File.read(current_file)
  master = File.read(master_file)
  
  current_results = parse_results(current)
  master_results = parse_results(master)
  
  puts ""
  puts "=" * 80
  puts "BENCHMARK COMPARISON: Current Branch vs Master"
  puts "=" * 80
  puts ""
  printf "%-30s %15s %15s %12s\n", "Test", "Current", "Master", "Improvement"
  puts "-" * 80
  
  current_results.each do |test, current_ips|
    master_ips = master_results[test]
    next unless master_ips
    
    improvement = ((current_ips - master_ips) / master_ips * 100).round(1)
    
    printf "%-30s %15s %15s %11s%%\n", 
      test, 
      "%.2fM" % (current_ips / 1_000_000),
      "%.2fM" % (master_ips / 1_000_000),
      "%+.1f" % improvement
  end
  
  puts "=" * 80
end

# Main execution
if ORIGINAL_BRANCH == 'master'
  # Just run benchmark on master
  eval(BENCHMARK_SCRIPT)
else
  # Create temp script
  temp_script = Tempfile.new(['benchmark', '.rb'])
  temp_script.write(BENCHMARK_SCRIPT)
  temp_script.close
  
  # Run on current branch
  puts "Running benchmark on current branch..."
  current_output = Tempfile.new(['benchmark_current', '.txt'])
  current_output.close
  
  system("cd #{__dir__} && ruby #{temp_script.path} > #{current_output.path} 2>&1", exception: true)
  
  # Switch to master and run
  puts "\nSwitching to master branch..."
  master_output = Tempfile.new(['benchmark_master', '.txt'])
  master_output.close
  
  system("git checkout master -q", exception: true)
  system("cd #{__dir__} && ruby #{temp_script.path} > #{master_output.path} 2>&1", exception: true)
  
  # Switch back to original branch
  system("git checkout #{ORIGINAL_BRANCH} -q", exception: true)
  puts "Switched back to #{ORIGINAL_BRANCH}"
  
  # Display comparison
  compare_results(current_output.path, master_output.path)
  
  # Cleanup
  temp_script.unlink
  current_output.unlink
  master_output.unlink
end
