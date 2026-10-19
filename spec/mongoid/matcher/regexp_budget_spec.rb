# frozen_string_literal: true

require 'benchmark'
require 'spec_helper'

describe Mongoid::Matcher::RegexpBudget do
  # Costly but bounded on every supported Ruby: unanchored, so every branch is
  # tried at every position, and with no nested quantifier there is nothing to
  # backtrack exponentially. What it costs still varies a lot by engine, about
  # 6ms a match on MRI against 110ms on JRuby, so anything asserting on that
  # cost calibrates rather than hard-coding it.
  #
  # A pattern built out of nested quantifiers would be wrong here. Those are
  # merely slow only where Ruby memoizes matching, which arrived in 3.2; on
  # 2.7 through 3.1 they backtrack exponentially and never finish.
  let(:slow_pattern) { BSON::Regexp::Raw.new("(?:#{(1..300).map { |i| "a#{i}" }.join('|')})Z") }
  let(:slow_subject) { 'a' * 5_000 }

  # Backtracks exponentially: the backreference disables memoization, so this
  # runs orders of magnitude longer than the limit and has to be interrupted.
  #
  # The subject is kept short enough that the match still finishes on its own,
  # in roughly 4.5 seconds against a 0.2 second limit. That way a Ruby whose
  # engine does not check for interrupts mid-match fails these examples
  # visibly instead of hanging the run.
  let(:catastrophic_pattern) { BSON::Regexp::Raw.new('^(a+)+\1?$') }
  let(:catastrophic_subject) { "#{'a' * 28}X" }

  let(:cheap_pattern) { BSON::Regexp::Raw.new('\Aabc\z') }

  # A budget is only opened for a selector that carries a pattern, so anything
  # exercising one has to hand .open something to bound.
  let(:regexp_selector) { { 'name' => /\Aabc\z/ } }

  describe '.open' do
    context 'when no limit is configured' do
      config_override :in_memory_regexp_time_limit, nil

      it 'does not establish a budget' do
        described_class.open(regexp_selector) do
          expect(described_class.remaining).to be_nil
        end
      end
    end

    context 'when the configured limit is zero' do
      config_override :in_memory_regexp_time_limit, 0

      # Zero is a common way to spell "disabled". Taken literally it would mean
      # a budget spent before the first match, so every in-memory query
      # carrying a pattern would raise rather than run.
      it 'does not establish a budget' do
        described_class.open(regexp_selector) do
          expect(described_class.remaining).to be_nil
        end
      end

      it 'still performs matches' do
        result = described_class.open(regexp_selector) do
          described_class.match?('abc', cheap_pattern)
        end

        expect(result).to eq(0)
      end
    end

    context 'when a limit is configured' do
      config_override :in_memory_regexp_time_limit, 5.0

      it 'establishes the budget for the duration of the block' do
        described_class.open(regexp_selector) do
          expect(described_class.remaining).to be_within(0.01).of(5.0)
        end
      end

      it 'returns the value of the block' do
        expect(described_class.open(regexp_selector) { :result }).to eq(:result)
      end

      it 'clears the budget when the block returns' do
        described_class.open(regexp_selector) { nil }
        expect(described_class.remaining).to be_nil
      end

      it 'clears the budget when the block raises' do
        expect { described_class.open(regexp_selector) { raise 'boom' } }.to raise_error('boom')
        expect(described_class.remaining).to be_nil
      end

      it 'joins the enclosing budget rather than starting a new one' do
        described_class.open(regexp_selector) do
          described_class.match?(slow_subject, slow_pattern)
          spent = 5.0 - described_class.remaining
          expect(spent).to be > 0

          described_class.open(regexp_selector) do
            expect(described_class.remaining).to be_within(0.01).of(5.0 - spent)
          end
        end
      end

      context 'when the selector carries no regular expression' do
        it 'does not establish a budget' do
          described_class.open('name' => 'abc') do
            expect(described_class.remaining).to be_nil
          end
        end

        it 'does not put a deadline on the block' do
          # The limit bounds regular expressions, not in-memory work at large.
          # On the Timeout path a scope with nothing to bound used to fail any
          # slow scan -- an embedded association of any size, say -- with an
          # error about regular expressions.
          stub_const('Mongoid::Matcher::RegexpBudget::PER_REGEXP_TIMEOUT', false)
          Mongoid::Config.in_memory_regexp_time_limit = 0.2

          expect do
            described_class.open('name' => 'abc') { sleep 0.3 }
          end.not_to raise_error
        end

        it 'keeps a nested scope from scanning the selector again' do
          described_class.open('name' => 'abc') do
            expect(Mongoid::Threaded.has?(Mongoid::Threaded::REGEXP_BUDGET_KEY)).to be(true)
          end
        end
      end

      context 'when the selector carries a string $regex' do
        # FieldExpression turns it into a pattern at match time, so it needs
        # bounding just as much as a Regexp written out in the selector does.
        it 'establishes a budget' do
          described_class.open('name' => { '$regex' => 'abc' }) do
            expect(described_class.remaining).to be_within(0.01).of(5.0)
          end
        end
      end

      context 'when the selector nests a regular expression' do
        it 'establishes a budget' do
          described_class.open('$or' => [ { 'name' => 'abc' }, { 'name' => /abc/ } ]) do
            expect(described_class.remaining).to be_within(0.01).of(5.0)
          end
        end
      end
    end
  end

  describe '.limit_for' do
    context 'when a limit is configured' do
      config_override :in_memory_regexp_time_limit, 5.0

      it 'is the limit for a selector carrying a regular expression' do
        expect(described_class.limit_for(regexp_selector)).to eq(5.0)
      end

      it 'is the limit for a selector carrying a string $regex' do
        expect(described_class.limit_for('name' => { '$regex' => 'abc' })).to eq(5.0)
      end

      it 'is the limit for a selector nesting a regular expression' do
        expect(described_class.limit_for('$or' => [ { 'name' => 'abc' }, { 'name' => /abc/ } ])).to eq(5.0)
      end

      it 'is nil for a selector carrying no regular expression' do
        expect(described_class.limit_for('name' => 'abc')).to be_nil
      end

      it 'is nil for an empty selector' do
        expect(described_class.limit_for({})).to be_nil
      end
    end

    context 'when no limit is configured' do
      config_override :in_memory_regexp_time_limit, nil

      # Nothing would be bounded, so a caller that only rearranges its work to
      # make room for a budget has no reason to.
      it 'is nil even for a selector carrying a regular expression' do
        expect(described_class.limit_for(regexp_selector)).to be_nil
      end
    end

    context 'when the configured limit is zero' do
      config_override :in_memory_regexp_time_limit, 0

      it 'is nil even for a selector carrying a regular expression' do
        expect(described_class.limit_for(regexp_selector)).to be_nil
      end
    end
  end

  describe '.open_with' do
    config_override :in_memory_regexp_time_limit, 5.0

    it 'establishes a budget for the limit it is given, not the configured one' do
      described_class.open_with(2.0) do
        expect(described_class.remaining).to be_within(0.01).of(2.0)
      end
    end

    it 'returns the value of the block' do
      expect(described_class.open_with(2.0) { :result }).to eq(:result)
    end

    it 'clears the budget when the block returns' do
      described_class.open_with(2.0) { nil }
      expect(described_class.remaining).to be_nil
    end

    context 'when given no limit' do
      it 'does not establish a budget' do
        described_class.open_with(nil) do
          expect(described_class.remaining).to be_nil
        end
      end

      # A caller that read the limit, found nothing to bound and arranged its
      # work accordingly must not have a deadline imposed on it by a later read
      # of the same setting. On the Timeout path that deadline would cover
      # whatever the caller went on to do, which here is a query and a mutation
      # of every match.
      it 'does not put a deadline on the block' do
        stub_const('Mongoid::Matcher::RegexpBudget::PER_REGEXP_TIMEOUT', false)
        Mongoid::Config.in_memory_regexp_time_limit = 0.2

        expect do
          described_class.open_with(nil) { sleep 0.3 }
        end.not_to raise_error
      end

      it 'leaves an enclosing budget alone' do
        described_class.open(regexp_selector) do
          described_class.open_with(nil) do
            expect(described_class.remaining).to be_within(0.01).of(5.0)
          end
        end
      end
    end
  end

  describe '.match?' do
    context 'when no budget is open' do
      it 'performs the match' do
        expect(described_class.match?('abc', cheap_pattern)).to eq(0)
      end

      it 'returns nil when the value does not match' do
        expect(described_class.match?('xyz', cheap_pattern)).to be_nil
      end

      it "leaves an application's own Regexp timeout alone" do
        # With nothing of ours to blame it on, translating the error would name
        # a limit that is not set and advise unsetting it.
        skip 'per-Regexp timeouts unavailable' unless described_class::PER_REGEXP_TIMEOUT

        pattern = Regexp.new(catastrophic_pattern.pattern, timeout: 0.2)

        expect do
          described_class.match?(catastrophic_subject, pattern)
        end.to raise_error(Regexp::TimeoutError)
      end
    end

    context 'when a budget is open' do
      config_override :in_memory_regexp_time_limit, 5.0

      it 'performs the match' do
        described_class.open(regexp_selector) do
          expect(described_class.match?('abc', cheap_pattern)).to eq(0)
        end
      end

      it 'accepts an already compiled Regexp' do
        described_class.open(regexp_selector) do
          expect(described_class.match?('abc', /\Aabc\z/)).to eq(0)
        end
      end

      it 'preserves the options of the condition' do
        described_class.open(regexp_selector) do
          expect(described_class.match?('ABC', BSON::Regexp::Raw.new('\Aabc\z', 'i'))).to eq(0)
        end
      end

      it 'preserves the encoding of the condition' do
        # The condition is rebuilt to carry the timeout, so its source, options
        # and encoding all have to survive the round trip.
        described_class.open(regexp_selector) do
          expect(described_class.match?('é', /\Aé+\z/u)).to eq(0)
        end
      end

      it 'charges the elapsed time against the budget' do
        described_class.open(regexp_selector) do
          before = described_class.remaining
          described_class.match?(slow_subject, slow_pattern)
          expect(described_class.remaining).to be < before
        end
      end

      it 'compiles a pattern once for the scope rather than once per match' do
        skip 'per-Regexp timeouts unavailable' unless described_class::PER_REGEXP_TIMEOUT

        # An already compiled condition, so that the only Regexp.new in play is
        # the one baking in the timeout.
        allow(Regexp).to receive(:new).and_call_original

        described_class.open(regexp_selector) do
          10.times { described_class.match?('abc', /\Aabc\z/) }
        end

        expect(Regexp).to have_received(:new).once
      end
    end

    context 'when the patterns are expensive to compile but cheap to run' do
      config_override :in_memory_regexp_time_limit, nil

      # Thousands of alternations cost far more to compile than to run against
      # a subject that fails at the first character. Charging only the match
      # would leave a selector full of these -- a long $or, say -- able to
      # spend as much time as it liked without the budget noticing.
      let(:costly_to_compile) do
        Array.new(200) do |n|
          BSON::Regexp::Raw.new("(?:#{(1..2_000).map { |i| "b#{n}x#{i}" }.join('|')})Z")
        end
      end

      before do
        # Building the fixtures is not free either, so it happens before the
        # clock starts rather than inside the block being measured.
        pattern = costly_to_compile.first.pattern
        cost = Benchmark.realtime { Regexp.new(pattern) }
        Mongoid::Config.in_memory_regexp_time_limit = cost * 5
      end

      it 'charges compilation against the budget' do
        skip 'per-Regexp timeouts unavailable' unless described_class::PER_REGEXP_TIMEOUT

        expect do
          described_class.open(regexp_selector) do
            costly_to_compile.each { |pattern| described_class.match?('x', pattern) }
          end
        end.to raise_error(Mongoid::Errors::InMemoryRegexpTimeout)
      end
    end

    context 'when the application has set a stricter Regexp timeout' do
      config_override :in_memory_regexp_time_limit, 5.0

      around do |example|
        skip 'per-Regexp timeouts unavailable' unless described_class::PER_REGEXP_TIMEOUT

        was = Regexp.timeout
        Regexp.timeout = 0.2
        begin
          example.run
        ensure
          Regexp.timeout = was
        end
      end

      it 'does not loosen it to the budget limit' do
        # Baking the whole limit in would override the global and leave the
        # application less protected than it configured itself to be.
        elapsed = Benchmark.realtime do
          expect do
            described_class.open(regexp_selector) do
              described_class.match?(catastrophic_subject, catastrophic_pattern)
            end
          end.to raise_error(Mongoid::Errors::InMemoryRegexpTimeout)
        end

        expect(elapsed).to be < 1.0
      end

      it 'names the limit that fired rather than the configured one' do
        # Naming the configured 5.0 would state a time that was never spent,
        # and send the reader after a setting that is not the one in the way.
        expect do
          described_class.open(regexp_selector) do
            described_class.match?(catastrophic_subject, catastrophic_pattern)
          end
        end.to raise_error(Mongoid::Errors::InMemoryRegexpTimeout, /exceeded the 0\.2 second limit/)
      end
    end

    context 'when a global Regexp timeout fires with nothing baked' do
      config_override :in_memory_regexp_time_limit, 5.0

      # The counterpart to the context above, for the engine that raises
      # Regexp::TimeoutError but will not take a per-Regexp timeout: JRuby. The
      # pattern carries nothing there, so it reports nil and the global is the
      # only thing that can have fired.
      around do |example|
        skip 'no Regexp timeouts at all' unless defined?(Regexp::TimeoutError)

        was = Regexp.timeout
        Regexp.timeout = 0.2
        begin
          example.run
        ensure
          Regexp.timeout = was
        end
      end

      before { stub_const('Mongoid::Matcher::RegexpBudget::PER_REGEXP_TIMEOUT', false) }

      it 'names the global limit rather than the budget limit' do
        expect do
          described_class.open_with(5.0) do
            described_class.match?(catastrophic_subject, catastrophic_pattern)
          end
        end.to raise_error(Mongoid::Errors::InMemoryRegexpTimeout, /exceeded the 0\.2 second limit/)
      end
    end

    context 'when the accumulated cost exceeds the limit' do
      config_override :in_memory_regexp_time_limit, nil

      # Calibrated rather than hard-coded: one match of the fixture costs about
      # 6ms on MRI and 110ms on JRuby, so a fixed limit would be either
      # unreachable on one or tripped by a single match on the other.
      before do
        regexp = Regexp.new(slow_pattern.pattern)
        3.times { slow_subject =~ regexp }
        cost = Benchmark.realtime { slow_subject =~ regexp }
        Mongoid::Config.in_memory_regexp_time_limit = cost * 5
      end

      it 'raises once the budget is spent' do
        expect do
          described_class.open(regexp_selector) do
            100.times { described_class.match?(slow_subject, slow_pattern) }
          end
        end.to raise_error(Mongoid::Errors::InMemoryRegexpTimeout)
      end

      it 'names the configured limit' do
        # The counterpart to the stricter-Regexp.timeout example above: where
        # the budget itself is what ran out, its own limit is the one to name.
        limit = Regexp.escape(Mongoid::Config.in_memory_regexp_time_limit.to_s)

        expect do
          described_class.open(regexp_selector) do
            100.times { described_class.match?(slow_subject, slow_pattern) }
          end
        end.to raise_error(Mongoid::Errors::InMemoryRegexpTimeout, /exceeded the #{limit} second limit/)
      end

      it 'does not raise for a single match under that same limit' do
        expect do
          described_class.open(regexp_selector) { described_class.match?(slow_subject, slow_pattern) }
        end.not_to raise_error
      end

      it 'does not raise when no single match and no accumulation exceeds the limit' do
        expect do
          described_class.open(regexp_selector) do
            100.times { described_class.match?('abc', cheap_pattern) }
          end
        end.not_to raise_error
      end
    end
  end

  context 'when a single match runs far longer than the limit' do
    config_override :in_memory_regexp_time_limit, 0.2

    context 'when the Ruby in use supports per-Regexp timeouts' do
      # Keyed to the capability, not the version: JRuby 10 reports Ruby 3.4
      # but cannot be given a per-Regexp timeout, so it runs the Timeout path.
      before do
        skip 'per-Regexp timeouts unavailable' unless described_class::PER_REGEXP_TIMEOUT
      end

      it 'interrupts the match' do
        expect do
          described_class.open(regexp_selector) do
            described_class.match?(catastrophic_subject, catastrophic_pattern)
          end
        end.to raise_error(Mongoid::Errors::InMemoryRegexpTimeout)
      end
    end

    context 'when the Ruby in use has no per-Regexp timeouts' do
      before do
        stub_const('Mongoid::Matcher::RegexpBudget::PER_REGEXP_TIMEOUT', false)
      end

      it 'interrupts the match with Timeout' do
        expect do
          described_class.open(regexp_selector) do
            described_class.match?(catastrophic_subject, catastrophic_pattern)
          end
        end.to raise_error(Mongoid::Errors::InMemoryRegexpTimeout)
      end

      it 'interrupts an unprotected block part way through' do
        completed = false

        expect do
          described_class.open(regexp_selector) do
            sleep 0.3
            completed = true
          end
        end.to raise_error(Mongoid::Errors::InMemoryRegexpTimeout)

        expect(completed).to be(false)
      end

      it 'lets a protected block finish before delivering the interruption' do
        # remove_all mutates association state inside its scope. Deferring the
        # exception, rather than forgoing it, is what lets that scope stay
        # interruptible without unbind_one being torn in half.
        completed = false

        expect do
          described_class.open(regexp_selector) do
            described_class.protect do
              sleep 0.3
              completed = true
            end
          end
        end.to raise_error(Mongoid::Errors::InMemoryRegexpTimeout)

        expect(completed).to be(true)
      end
    end
  end

  describe Mongoid::Matcher::RegexpBudget::Budget do
    describe '#compile' do
      let(:budget) { described_class.new(5.0) }

      it 'returns a pattern matching the condition' do
        expect(budget.compile(BSON::Regexp::Raw.new('\Aabc\z'))).to match('abc')
      end

      it 'reuses the pattern compiled for an equal condition' do
        # FieldExpression builds a fresh BSON::Regexp::Raw for every $regex it
        # evaluates, so its own memo is worth nothing from one document to the
        # next and the source would be compiled once per document. Raw does not
        # override hash, either, so the cache cannot be keyed on the condition
        # itself.
        first = budget.compile(BSON::Regexp::Raw.new('abc', 'i'))
        second = budget.compile(BSON::Regexp::Raw.new('abc', 'i'))

        expect(second).to equal(first)
      end

      it 'does not confuse conditions differing only in their options' do
        insensitive = budget.compile(BSON::Regexp::Raw.new('abc', 'i'))
        sensitive = budget.compile(BSON::Regexp::Raw.new('abc'))

        expect(insensitive).to match('ABC')
        expect(sensitive).not_to match('ABC')
      end

      it 'reuses the pattern compiled for an equal Regexp' do
        expect(budget.compile(/abc/i)).to equal(budget.compile(/abc/i))
      end

      it 'raises for a condition that is not a regular expression' do
        expect { budget.compile('abc') }.to raise_error(ArgumentError, /Not a regular expression/)
      end
    end
  end
end
