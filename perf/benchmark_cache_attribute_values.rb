#!/usr/bin/env ruby
# frozen_string_literal: true
# rubocop:todo all

# Benchmark script to compare field access performance between master and current branch.
# This measures timing improvements from field access caching optimizations.
#
# Usage:
#   ruby perf/benchmark_cache_attribute_values.rb
#
# The script will:
#   1. Run benchmark on current branch
#   2. Switch to master and run benchmark
#   3. Switch back to original branch
#   4. Display comparison

require "tempfile"
require "fileutils"
require "tmpdir"
require "set"

# Save original branch
ORIGINAL_BRANCH = `git rev-parse --abbrev-ref HEAD`.strip

# Create temp benchmark script that can run on any branch
BENCHMARK_SCRIPT = <<~'RUBY'
  repo_root = ENV.fetch("MONGOID_BENCH_REPO_ROOT")
  $LOAD_PATH.unshift(File.join(repo_root, "lib"))

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
    cache_enabled = ENV.fetch("MONGOID_BENCH_CACHE_MODE", "enabled") == "enabled"
    Mongoid::Config.cache_attribute_values = cache_enabled
    puts "Field caching: #{cache_enabled ? 'enabled' : 'disabled'}"
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

  # Isolated documents for each benchmark path.
  cold_band = Band.new(name: "Cold Read Band")
  dotted_band = Band.new(tags: { "genre" => "rock", "era" => "80s" })
  projected_band = Band.only(:name).find(band.id)
  string_write_band = Band.new(name: "Write Path Band")
  scalar_band = Band.new(member_count: 0)
  array_band = Band.new(genres: %w[rock metal])
  hash_band = Band.new(tags: { "genre" => "rock", "era" => "80s" })
  write_then_read_band = Band.new(name: "Initial Name")

  string_write_counter = 0
  scalar_counter = 0
  array_counter = 0
  hash_counter = 0
  write_then_read_counter = 0
  mem_time = (ENV["MONGOID_BENCH_MEM_TIME"] || "3").to_i
  mem_warmup = (ENV["MONGOID_BENCH_MEM_WARMUP"] || "1").to_i

  # Run GC before starting to ensure clean state
  3.times { GC.start }

  # In-memory microbenchmarks: disable GC to reduce runtime noise from collections.
  GC.disable
  Benchmark.ips do |x|
    x.config(time: mem_time, warmup: mem_warmup)

    puts "\n[ Existing Benchmarks ]"
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

    x.report("iterate embedded (5 docs)") do
      person.addresses.each do |addr|
        addr.street
        addr.city
        addr.post_code
      end
    end

    x.report("write then read") do
      band.name = "Modified Band"
      band.name
    end

    puts "\n[ Split Write/Read Paths ]"
    x.report("cold string read") do
      if cache_available
        cache = cold_band.instance_variable_get(:@__demongoized_cache)
        cache&.delete(:name)
        cache&.delete("name")
      end
      cold_band.name
    end

    x.report("dotted field read 10x") do
      10.times { dotted_band.read_attribute("tags.genre") }
    end

    x.report("projected field access 10x") do
      10.times { projected_band.name }
    end

    x.report("string write only") do
      string_write_counter += 1
      string_write_band.name = "Modified Band #{string_write_counter}"
    end

    x.report("scalar replace then read") do
      scalar_counter += 1
      scalar_band.member_count = scalar_counter
      scalar_band.member_count
    end

    x.report("array in-place mutate then read") do
      arr = array_band.genres
      arr << "genre_#{array_counter}"
      arr.pop
      array_counter += 1
      array_band.genres
    end

    x.report("hash in-place mutate then read") do
      key = "k#{hash_counter}"
      hash_band.tags[key] = hash_counter
      hash_band.tags.delete(key)
      hash_counter += 1
      hash_band.tags
    end

    x.report("string write then read") do
      write_then_read_counter += 1
      write_then_read_band.name = "Modified Name #{write_then_read_counter}"
      write_then_read_band.name
    end

  end
  GC.enable

RUBY

def parse_results(text)
  results = {}
  return results unless text

  # benchmark-ips lines include "(...)" but fixed-iteration DB lines do not.
  text.scan(/^\s*(.+?)\s+([\d.]+)\s*([kM]?)\s+(?:\([^)]+\)\s+)?i\/s/) do |name, ips, suffix|
    multiplier =
      case suffix
      when 'M' then 1_000_000
      when 'k' then 1_000
      else 1
      end
    value = ips.to_f * multiplier
    results[name.strip] = value
  end
  results
end

def median(values)
  sorted = values.sort
  size = sorted.size
  return 0 if size == 0

  midpoint = size / 2
  if size.odd?
    sorted[midpoint]
  else
    (sorted[midpoint - 1] + sorted[midpoint]) / 2.0
  end
end

def aggregate_results(files)
  parsed = files.map { |f| parse_results(File.read(f.path)) }
  test_names = parsed.flat_map(&:keys).uniq

  test_names.each_with_object({}) do |name, acc|
    values = parsed.map { |h| h[name] }.compact
    next if values.empty?

    acc[name] = median(values)
  end
end

def format_ips(ips)
  if ips >= 1_000_000
    "%.1fM" % (ips / 1_000_000.0)
  elsif ips >= 1_000
    "%.1fk" % (ips / 1_000.0)
  else
    "%.1f" % ips
  end
end

def benchmark_groups
  {
    "Core Field Reads" => [
      "String 10x",
      "Integer 10x",
      "Float 10x",
      "Boolean 10x",
      "Date 10x",
      "Time 10x",
      "Hash 10x",
      "Array 10x",
      "Range 10x",
      "BSON::ObjectId 10x",
      "iterate embedded (5 docs)"
    ],
    "Read/Write Scenarios" => [
      "write then read",
      "cold string read",
      "dotted field read 10x",
      "projected field access 10x",
      "string write only",
      "scalar replace then read",
      "array in-place mutate then read",
      "hash in-place mutate then read",
      "string write then read"
    ]
  }
end

def print_table_header
  printf "%-30s  %15s  %16s  %12s\n", "Test", "Cache enabled", "Cache disabled", "Master"
  puts [ "━" * 30, "━" * 15, "━" * 16, "━" * 12 ].join("  ")
end

def print_table_separator
  puts [ "─" * 30, "─" * 15, "─" * 16, "─" * 12 ].join("  ")
end

def compare_results(cache_enabled_files, cache_disabled_files, master_files)
  cache_enabled_results = aggregate_results(cache_enabled_files)
  cache_disabled_results = aggregate_results(cache_disabled_files)
  master_results = aggregate_results(master_files)
  rows = []

  cache_enabled_results.each do |test, cache_enabled_ips|
    cache_disabled_ips = cache_disabled_results[test]
    master_ips = master_results[test]
    next unless cache_disabled_ips && master_ips

    rows << {
      test: test,
      cache_enabled: cache_enabled_ips,
      cache_disabled: cache_disabled_ips,
      master: master_ips
    }
  end

  puts ""
  puts "=" * 79
  puts "BENCHMARK COMPARISON (median): Cache Enabled vs Cache Disabled vs Master"
  puts "=" * 79

  printed = Set.new

  benchmark_groups.each do |group_name, tests|
    group_rows = rows.select { |r| tests.include?(r[:test]) }
    next if group_rows.empty?

    puts ""
    puts "[ #{group_name} ]"
    print_table_header

    group_rows.each_with_index do |row, index|
      printed << row[:test]
      printf "%-30s  %15s  %16s  %12s\n",
        row[:test],
        format_ips(row[:cache_enabled]),
        format_ips(row[:cache_disabled]),
        format_ips(row[:master])
      print_table_separator if index < group_rows.length - 1
    end
  end

  other_rows = rows.reject { |r| printed.include?(r[:test]) }
  unless other_rows.empty?
    puts ""
    puts "[ Other ]"
    print_table_header

    other_rows.each_with_index do |row, index|
      printf "%-30s  %15s  %16s  %12s\n",
        row[:test],
        format_ips(row[:cache_enabled]),
        format_ips(row[:cache_disabled]),
        format_ips(row[:master])
      print_table_separator if index < other_rows.length - 1
    end
  end

  puts ""
  puts "Legend:"
  puts "  Cache enabled  - current branch with cache_attribute_values=true."
  puts "  Cache disabled - current branch with cache_attribute_values=false; all other branch optimizations remain active."
  puts "  Master         - local master branch baseline, where attribute-value caching is unavailable."
  puts "  Values         - median iterations per second across independent process runs; higher is better."
  puts "=" * 79
end

# Main execution
if ORIGINAL_BRANCH == 'master'
  # Just run benchmark on master
  eval(BENCHMARK_SCRIPT)
else
  repetitions = [ (ENV["MONGOID_BENCH_REPETITIONS"] || "2").to_i, 1 ].max

  # Get repository root
  repo_root = File.expand_path('..', __dir__)

  # Create temp script
  temp_script = Tempfile.new(['benchmark', '.rb'])
  temp_script.write(BENCHMARK_SCRIPT)
  temp_script.close

  cache_enabled_outputs = []
  cache_disabled_outputs = []
  master_outputs = []
  master_worktree = nil

  begin
    puts "Running benchmark on current branch with cache enabled (#{repetitions} runs)..."
    repetitions.times do |i|
      puts "  cache enabled run #{i + 1}/#{repetitions}"
      output = Tempfile.new(["benchmark_cache_enabled_#{i}", '.txt'])
      output.close
      system(
        {
          "MONGOID_BENCH_REPO_ROOT" => repo_root,
          "MONGOID_BENCH_CACHE_MODE" => "enabled"
        },
        "bundle", "exec", "ruby", temp_script.path,
        chdir: repo_root,
        out: output.path,
        err: [ :child, :out ],
        exception: true
      )
      cache_enabled_outputs << output
    end

    puts "\nRunning benchmark on current branch with cache disabled (#{repetitions} runs)..."
    repetitions.times do |i|
      puts "  cache disabled run #{i + 1}/#{repetitions}"
      output = Tempfile.new(["benchmark_cache_disabled_#{i}", '.txt'])
      output.close
      system(
        {
          "MONGOID_BENCH_REPO_ROOT" => repo_root,
          "MONGOID_BENCH_CACHE_MODE" => "disabled"
        },
        "bundle", "exec", "ruby", temp_script.path,
        chdir: repo_root,
        out: output.path,
        err: [ :child, :out ],
        exception: true
      )
      cache_disabled_outputs << output
    end

    # Use a temporary worktree for master to avoid modifying/stashing current branch.
    puts "\nPreparing temporary master worktree..."
    master_worktree = Dir.mktmpdir("mongoid-bench-master-")
    system("git", "-C", repo_root, "worktree", "add", "--detach", master_worktree, "master", "-q", exception: true)

    # Bundle install might be needed if dependencies differ
    puts "Ensuring dependencies are installed on master..."
    system("bundle", "install", "--quiet", chdir: master_worktree, out: File::NULL, err: File::NULL)

    puts "Running benchmark on master branch (#{repetitions} runs)..."
    repetitions.times do |i|
      puts "  master run #{i + 1}/#{repetitions}"
      output = Tempfile.new(["benchmark_master_#{i}", '.txt'])
      output.close
      system(
        { "MONGOID_BENCH_REPO_ROOT" => master_worktree },
        "bundle", "exec", "ruby", temp_script.path,
        chdir: master_worktree,
        out: output.path,
        err: [ :child, :out ],
        exception: true
      )
      master_outputs << output
    end
  ensure
    if master_worktree
      system("git", "-C", repo_root, "worktree", "remove", master_worktree, "--force")
      FileUtils.remove_entry(master_worktree, true) if File.exist?(master_worktree)
    end
  end

  # Display comparison
  compare_results(cache_enabled_outputs, cache_disabled_outputs, master_outputs)

  # Cleanup
  temp_script.unlink
  cache_enabled_outputs.each(&:unlink)
  cache_disabled_outputs.each(&:unlink)
  master_outputs.each(&:unlink)
end
