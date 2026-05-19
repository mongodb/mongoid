# frozen_string_literal: true

require 'spec_helper'

# Atomic operations (inc, bit, set, etc.) must not fire flush or commit
# callbacks, because they did not do so before the changeset layer was
# introduced. When an atomic op and a regular save share the same changeset,
# callbacks should fire exactly once (driven by the save entry).
describe 'atomic operation callbacks' do
  let!(:person) { Person.create!(age: 10, score: 50, aliases: %w[foo bar]) }
  let(:events) { [] }

  before do
    ev = events
    Person.before_flush { ev << :before_flush }
    Person.after_flush  { ev << :after_flush  }
    Person.after_commit { ev << :commit       }
  end

  after do
    Person.reset_callbacks(:flush)
    Person.reset_callbacks(:commit)
  end

  shared_examples 'an atomic op that suppresses callbacks' do
    it 'does not fire flush or commit callbacks' do
      subject
      expect(events).to be_empty
    end
  end

  describe '#inc' do
    subject { person.inc(age: 1) }

    it_behaves_like 'an atomic op that suppresses callbacks'
  end

  describe '#bit' do
    subject { person.bit(score: { or: 1 }) }

    it_behaves_like 'an atomic op that suppresses callbacks'
  end

  describe '#set_max' do
    subject { person.set_max(score: 999) }

    it_behaves_like 'an atomic op that suppresses callbacks'
  end

  describe '#set_min' do
    subject { person.set_min(score: 1) }

    it_behaves_like 'an atomic op that suppresses callbacks'
  end

  describe '#mul' do
    subject { person.mul(age: 2) }

    it_behaves_like 'an atomic op that suppresses callbacks'
  end

  describe '#pop' do
    subject { person.pop(aliases: 1) }

    it_behaves_like 'an atomic op that suppresses callbacks'
  end

  describe '#pull' do
    subject { person.pull(aliases: 'foo') }

    it_behaves_like 'an atomic op that suppresses callbacks'
  end

  describe '#pull_all' do
    subject { person.pull_all(aliases: %w[foo]) }

    it_behaves_like 'an atomic op that suppresses callbacks'
  end

  describe '#add_to_set' do
    subject { person.add_to_set(aliases: 'baz') }

    it_behaves_like 'an atomic op that suppresses callbacks'
  end

  describe '#push' do
    subject { person.push(aliases: 'baz') }

    it_behaves_like 'an atomic op that suppresses callbacks'
  end

  describe '#rename' do
    subject { person.rename(title: :ssn) }

    it_behaves_like 'an atomic op that suppresses callbacks'
  end

  describe '#set' do
    subject { person.set(title: 'Sir') }

    it_behaves_like 'an atomic op that suppresses callbacks'
  end

  describe '#unset' do
    subject { person.unset(:title) }

    it_behaves_like 'an atomic op that suppresses callbacks'
  end

  describe 'combined with a save in the same changeset' do
    it 'fires each callback exactly once' do
      person.title = 'Sir'
      Mongoid.changeset do
        person.inc(age: 1)
        person.save
      end
      expect(events).to eq(%i[before_flush after_flush commit])
    end
  end
end
