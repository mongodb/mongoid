# frozen_string_literal: true

# Benchmarks Hash.demongoize performance for the three scenarios relevant to
# MONGOID-5684:
#
#   legacy     - legacy_hash_fields: true (BSON::Document returned as-is, O(1))
#   first read - legacy_hash_fields: false, BSON::Document input (conversion, O(N))
#   subsequent - legacy_hash_fields: false, plain Hash input (returns self, O(1))
#
# Each scenario uses a separate Benchmark.ips block with the config flag set
# before measurement begins, so the flag is stable during the entire run.
#
# Run with:
#   bundle exec ruby perf/benchmark_hash_demongoize.rb

require 'benchmark/ips'
require 'mongoid'

# ---------------------------------------------------------------------------
# Test documents
# ---------------------------------------------------------------------------

EMPTY = BSON::Document.new.freeze

FLAT = BSON::Document.new(
  'name' => 'Alice',
  'age' => 30,
  'active' => true,
  'score' => 9.5,
  'tag' => 'vip'
).freeze

# Three levels deep, 10 keys at each level. Leaf values are integers.
NESTED = BSON::Document.new(
  10.times.to_h do |i|
    [
      "l1_#{i}",
      BSON::Document.new(
        10.times.to_h do |j|
          [
            "l2_#{j}",
            BSON::Document.new(
              10.times.to_h { |k| [ "l3_#{k}", k ] }
            )
          ]
        end
      )
    ]
  end
).freeze

# Pre-converted plain Hash equivalents for the "subsequent read" scenario.
Mongoid.config.legacy_hash_fields = false
EMPTY_PLAIN  = Hash.demongoize(EMPTY)
FLAT_PLAIN   = Hash.demongoize(FLAT)
NESTED_PLAIN = Hash.demongoize(NESTED)
Mongoid.config.legacy_hash_fields = true

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

CASES = [
  [ 'empty (0 keys)',              EMPTY,  EMPTY_PLAIN ],
  [ 'flat (5 keys)',               FLAT,   FLAT_PLAIN ],
  [ 'nested (3 levels, 10 keys)',  NESTED, NESTED_PLAIN ]
].freeze

def section(title)
  puts "\n#{'=' * 60}"
  puts title
  puts '=' * 60
end

# ---------------------------------------------------------------------------
# Scenario 1: legacy behavior (flag = true)
# Config is set once before the block; all three cases share the same flag.
# ---------------------------------------------------------------------------

section 'Scenario 1: legacy_hash_fields: true (BSON::Document returned as-is)'

Mongoid.config.legacy_hash_fields = true
Benchmark.ips do |x|
  x.config(warmup: 2, time: 5)
  CASES.each do |label, bson, _|
    x.report(label) { Hash.demongoize(bson) }
  end
  x.compare!
end

# ---------------------------------------------------------------------------
# Scenario 2: first read (flag = false, BSON::Document input)
# This is the O(N) path: allocates and populates a new plain Hash.
# ---------------------------------------------------------------------------

section 'Scenario 2: legacy_hash_fields: false, BSON::Document input (first read)'

Mongoid.config.legacy_hash_fields = false
Benchmark.ips do |x|
  x.config(warmup: 2, time: 5)
  CASES.each do |label, bson, _|
    x.report(label) { Hash.demongoize(bson) }
  end
  x.compare!
end

# ---------------------------------------------------------------------------
# Scenario 3: subsequent reads (flag = false, plain Hash input)
# After the write-back in process_raw_attribute, attributes holds a plain Hash.
# This should be O(1): two type checks, one return.
# ---------------------------------------------------------------------------

section 'Scenario 3: legacy_hash_fields: false, plain Hash input (subsequent reads)'

Mongoid.config.legacy_hash_fields = false
Benchmark.ips do |x|
  x.config(warmup: 2, time: 5)
  CASES.each do |label, _, plain|
    x.report(label) { Hash.demongoize(plain) }
  end
  x.compare!
end

Mongoid.config.legacy_hash_fields = true
