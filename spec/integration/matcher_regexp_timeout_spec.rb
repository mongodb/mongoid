# frozen_string_literal: true

require 'benchmark'
require 'spec_helper'

describe 'in-memory regexp time limit' do
  # See the comment in spec/mongoid/matcher/regexp_budget_spec.rb: costly to
  # match but bounded on every supported Ruby. A pattern relying on nested
  # quantifiers would hang before Ruby 3.2, where the examples that have no
  # interrupt available could not stop it.
  let(:slow_pattern) { "(?:#{(1..300).map { |i| "a#{i}" }.join('|')})Z" }
  let(:slow_street) { 'a' * 5_000 }

  let(:person) do
    # Address derives its _id from the street, so the streets have to differ or
    # the embedded association collapses to a single document.
    Person.new(addresses: Array.new(30) { |i| Address.new(street: "#{slow_street}#{i}") })
  end

  let(:one_address) { Person.new(addresses: [ Address.new(street: slow_street) ]) }

  # What one match of the fixture costs on the machine running the suite. It
  # varies by more than an order of magnitude between implementations - around
  # 6ms on MRI, 110ms on JRuby - so the examples below calibrate against a
  # measurement instead of hard-coding a threshold that only holds on one.
  let(:single_match_cost) do
    regexp = Regexp.new(slow_pattern)
    3.times { slow_street =~ regexp }
    Benchmark.realtime { slow_street =~ regexp }
  end

  # Comfortably more than one match, comfortably less than twenty. The examples
  # only need the ordering to hold, so the margin either side is wide.
  let(:calibrated_limit) { single_match_cost * 5 }

  context 'when the limit is disabled' do
    config_override :in_memory_regexp_time_limit, nil

    it 'evaluates the query without a bound' do
      expect(person.addresses.where(street: { '$regex' => slow_pattern }).to_a).to eq([])
    end
  end

  context 'when a limit is configured' do
    config_override :in_memory_regexp_time_limit, nil

    before { Mongoid::Config.in_memory_regexp_time_limit = calibrated_limit }

    it 'leaves ordinary queries alone' do
      person = Person.new(addresses: [ Address.new(street: 'Clarkson') ])
      expect(person.addresses.where(street: { '$regex' => '\AClark' }).to_a.size).to eq(1)
    end

    it 'does not raise for a single document' do
      # The counterpart to the example below, and what makes it meaningful: one
      # document stays under the limit, so a scan that raises can only have got
      # there by accumulating cost across documents.
      expect do
        one_address.addresses.where(street: { '$regex' => slow_pattern }).to_a
      end.not_to raise_error
    end

    it 'raises for a scan over many documents under that same limit' do
      expect do
        person.addresses.where(street: { '$regex' => slow_pattern }).to_a
      end.to raise_error(Mongoid::Errors::InMemoryRegexpTimeout)
    end

    it 'raises when $in multiplies the cost within a single document' do
      conditions = Array.new(20) { BSON::Regexp::Raw.new(slow_pattern) }

      expect do
        one_address.addresses.where(street: { '$in' => conditions }).to_a
      end.to raise_error(Mongoid::Errors::InMemoryRegexpTimeout)
    end

    it 'raises through the public _matches? API' do
      # 20 conditions rather than one, because a single match is deliberately
      # kept well under the limit by the calibration above.
      conditions = Array.new(20) { BSON::Regexp::Raw.new(slow_pattern) }

      expect do
        person.addresses.first._matches?('street' => { '$in' => conditions })
      end.to raise_error(Mongoid::Errors::InMemoryRegexpTimeout)
    end
  end

  context 'when the pattern is pathological' do
    config_override :in_memory_regexp_time_limit, 0.2

    # The ticket's Case 1, verbatim. It backtracks exponentially and is the
    # reason the guard exists, so every entry point that evaluates a selector
    # in memory has to bound it. The subject is kept short enough that the
    # match still finishes on its own in a few seconds, so an entry point that
    # fails to bound it shows up as a failing example rather than a hung run.
    let(:evil_pattern) { '^(a+)+\1?$' }
    let(:evil_subject) { "#{'a' * 28}X" }

    it 'bounds a scan over an embedded association' do
      person = Person.new(addresses: [ Address.new(street: evil_subject) ])

      expect do
        person.addresses.where(street: { '$regex' => evil_pattern }).to_a
      end.to raise_error(Mongoid::Errors::InMemoryRegexpTimeout)
    end

    it 'bounds the public _matches? API' do
      expect do
        Address.new(street: evil_subject)._matches?('street' => { '$regex' => evil_pattern })
      end.to raise_error(Mongoid::Errors::InMemoryRegexpTimeout)
    end

    it 'bounds removal from a referenced association' do
      owner = Person.create!
      owner.posts.create!(title: evil_subject)

      expect do
        owner.posts.delete_all(title: { '$regex' => evil_pattern })
      end.to raise_error(Mongoid::Errors::InMemoryRegexpTimeout)
    end

    it 'deletes nothing when removal is bounded' do
      # The scan runs before the delete, so the error means what a caller would
      # take it to mean: the documents are still there.
      owner = Person.create!
      owner.posts.create!(title: evil_subject)

      expect do
        owner.posts.delete_all(title: { '$regex' => evil_pattern })
      end.to raise_error(Mongoid::Errors::InMemoryRegexpTimeout)

      expect(Post.count).to eq(1)
      expect(owner.reload.posts.size).to eq(1)
    end
  end

  context 'when the association being removed from has not been loaded' do
    config_override :in_memory_regexp_time_limit, 0.2

    let!(:owner) do
      person = Person.create!
      person.posts.create!(title: 'Testing')
      Person.find(person._id)
    end

    # The query that loads the association, which removal has to run before it
    # has anything to match against.
    let(:load_query) { owner.posts._target._unloaded }

    # A stall standing in for a slow network. It is longer than the limit, and
    # none of it is time spent on regular expressions.
    before do
      allow(load_query).to receive(:each).and_wrap_original do |original, *args, &block|
        sleep(0.3)
        original.call(*args, &block)
      end
    end

    it 'does not load it, so no query can be counted against the limit' do
      # On the Timeout path a deadline covering the fetch failed a slow query
      # with an error about regular expressions, and the asynchronous exception
      # could land inside the driver's socket read, leaving the connection with
      # unconsumed bytes. Nothing is fetched now: the scan sees only what the
      # association already holds.
      stub_const('Mongoid::Matcher::RegexpBudget::PER_REGEXP_TIMEOUT', false)

      expect do
        owner.posts.delete_all(title: { '$regex' => '\Azzz' })
      end.not_to raise_error

      expect(load_query).not_to have_received(:each)
    end

    it 'runs no pattern against documents it never loaded' do
      # The counterpart to the referenced-association examples below, where the
      # documents are in memory and the pattern is run against every one of
      # them. Here there is nothing to run it against, and the server applies
      # the same selector for the delete, so nothing is missed by not looking.
      expect(Mongoid::Matcher::RegexpBudget).not_to receive(:match?)

      owner.posts.delete_all(title: { '$regex' => '\Azzz' })
    end

    it 'still removes the documents that match' do
      expect(owner.posts.delete_all(title: { '$regex' => '\ATest' })).to eq(1)
      expect(Post.count).to eq(0)
      expect(owner.posts.size).to eq(0)
    end
  end

  context 'when removing documents from a referenced association' do
    config_override :in_memory_regexp_time_limit, nil

    let!(:owner) { Person.create! }

    before do
      30.times { owner.posts.create!(title: slow_street) }
      Mongoid::Config.in_memory_regexp_time_limit = calibrated_limit
    end

    it 'raises rather than scanning every loaded document' do
      expect do
        owner.posts.delete_all(title: { '$regex' => slow_pattern })
      end.to raise_error(Mongoid::Errors::InMemoryRegexpTimeout)
    end

    it 'leaves the documents in place' do
      expect do
        owner.posts.delete_all(title: { '$regex' => slow_pattern })
      end.to raise_error(Mongoid::Errors::InMemoryRegexpTimeout)

      expect(Post.count).to eq(30)
    end
  end
end
