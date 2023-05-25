# frozen_string_literal: true
# rubocop:todo all

require "benchmark/ips"
require "mongoid"

class DocWithHashes
  include Mongoid::Document

  field :h, type: Hash
end

doc = DocWithHashes.new(
  h: {
    "0" => {"d" => Time.now + rand },
    "1" => {"d" => Time.now + rand },
    "2" => {"a" => Time.now + rand, "b" => Time.now + rand },
    "3" => {"a" => Time.now + rand, "b" => Time.now + rand, "c" => Time.now + rand },
    "4" => {"a" => Time.now + rand, "b" => Time.now + rand, "c" => Time.now + rand, "ct" => true },
  }
)

SELECTORS = [
  DocWithHashes.where(:"h.1.a".exists => false),
  DocWithHashes.where(:"h.3.d".lt => "2021-04-19T23:05:34.142Z"),
  DocWithHashes.where(:"h.4.d".exists => false).or(:"h.4.ct" => true),
].map { |criteria| criteria.selector }

Benchmark.ips do |bm|
  bm.report("_matches? with BSON::Document") do
    Mongoid::Matcher.instance_variable_set(:@attributes_as_bson_doc, true)

    SELECTORS.each do |sel|
      doc._matches?(sel)
    end
  end

  bm.report("_matches? with indifferent key methods") do
    Mongoid::Matcher.instance_variable_set(:@attributes_as_bson_doc, false)

    SELECTORS.each do |sel|
      doc._matches?(sel)
    end
  end

  bm.compare!
end
