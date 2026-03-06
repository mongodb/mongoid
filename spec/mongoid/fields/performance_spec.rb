# frozen_string_literal: true

# rubocop:disable RSpec/ContextWording, RSpec/ExampleLength

require 'spec_helper'
require 'concurrent/array'

# Allocation tracking is optional (only available on MRI with allocation_stats gem)
begin
  require 'allocation_stats'
  allocation_stats_available = true
rescue LoadError
  allocation_stats_available = false
end

# Performance tests validate that field access optimizations achieve zero allocations.
# Core field types (String, Integer, Float, etc.) must have exactly 0 allocations
# to verify the caching optimization is working correctly.
describe 'Mongoid::Fields performance optimizations' do
  # Enable caching for all performance tests
  around do |example|
    original_value = Mongoid::Config.cache_attribute_values
    Mongoid::Config.cache_attribute_values = true
    example.run
  ensure
    Mongoid::Config.cache_attribute_values = original_value
  end

  let(:band) do
    Band.new(
      name: 'Test Band',
      origin: 'Test City',
      tags: { 'genre' => 'rock', 'era' => '80s' },
      genres: %w[rock metal],
      rating: 8.5,
      member_count: 4,
      active: true,
      founded: Date.current,
      updated: Time.current
    )
  end

  shared_examples 'zero allocation field access' do |field_name|
    it "achieves zero allocations for #{field_name}" do
      subject.public_send(field_name) # warm up
      stats = AllocationStats.trace { 10.times { subject.public_send(field_name) } }
      expect(stats.new_allocations.size).to eq(0)
    end
  end

  describe 'allocation optimizations' do
    before do
      skip 'allocation_stats gem not available' unless allocation_stats_available
    end

    context 'field access' do
      subject { band }

      %i[name tags genres member_count rating active updated founded].each do |field|
        include_examples 'zero allocation field access', field
      end

      it 'achieves zero allocations for BSON::ObjectId fields' do
        band.save!
        band.id # warm up
        stats = AllocationStats.trace { 10.times { band.id } }
        expect(stats.new_allocations.size).to eq(0)
      end

      it 'achieves zero allocations for Symbol fields' do
        # Use a test-specific class to avoid polluting Band with extra fields
        symbol_band_class = Class.new do
          include Mongoid::Document
          store_in collection: 'bands'
          field :status, type: Symbol
        end
        stub_const('SymbolBand', symbol_band_class)

        band = SymbolBand.new(status: :active)
        band.status # warm up
        stats = AllocationStats.trace { 10.times { band.status } }
        expect(stats.new_allocations.size).to eq(0)
      end

      it 'achieves zero allocations for Range fields' do
        band.decibels = (50..120)
        band.decibels # warm up
        stats = AllocationStats.trace { 10.times { band.decibels } }
        expect(stats.new_allocations.size).to eq(0)
      end
    end

    context 'field access after setter' do
      subject { band }

      { tags: { 'new' => 'value' }, name: 'New Name', updated: Time.current }.each do |field, value|
        it "maintains zero allocations after #{field} setter" do
          band.public_send("#{field}=", value)
          band.public_send(field) # warm up
          stats = AllocationStats.trace { 10.times { band.public_send(field) } }
          expect(stats.new_allocations.size).to eq(0)
        end
      end
    end

    context 'class-level methods' do
      it 'achieves zero allocations for database_field_name' do
        Band.database_field_name('name') # warm up
        stats = AllocationStats.trace { 10.times { Band.database_field_name('name') } }
        # NOTE: aliased fields require .dup for safety, which allocates.
        # This test uses 'name' which is not aliased, achieving zero allocations.
        expect(stats.new_allocations.size).to eq(0)
      end

      it 'achieves zero allocations for cleanse_localized_field_names' do
        Band.cleanse_localized_field_names('name') # warm up
        stats = AllocationStats.trace { 10.times { Band.cleanse_localized_field_names('name') } }
        expect(stats.new_allocations.size).to eq(0)
      end

      it 'handles aliased fields correctly' do
        # 'id' is aliased to '_id'
        expect(Band.database_field_name('id')).to eq('_id')
        expect(Band.database_field_name('name')).to eq('name')
      end
    end

    context 'database-loaded documents' do
      subject { loaded_band }

      before { band.save! }

      let(:loaded_band) { Band.find(band.id) }

      %i[name tags genres member_count rating active updated].each do |field|
        include_examples 'zero allocation field access', field
      end
    end
  end

  describe 'correctness verification' do
    it 'returns correct values for all field types' do
      expect(band.name).to eq('Test Band')
      expect(band.tags).to eq({ 'genre' => 'rock', 'era' => '80s' })
      expect(band.genres).to eq(%w[rock metal])
      expect(band.rating).to eq(8.5)
      expect(band.member_count).to eq(4)
      expect(band.active).to be(true)
    end

    it 'preserves getter-after-setter behavior' do
      band.name = 'New Band'
      expect(band.name).to eq('New Band')

      band.tags = { 'key' => 'value' }
      expect(band.tags).to eq({ 'key' => 'value' })

      band.rating = 9.5
      expect(band.rating).to eq(9.5)

      band.name = nil
      expect(band.name).to be_nil
    end
  end

  describe 'critical edge cases' do
    context 'Time field transformations' do
      it 'applies UTC conversion when configured' do
        time_with_zone = Time.new(2020, 1, 1, 12, 0, 0, '+03:00')
        band.updated = time_with_zone
        band.save!

        reloaded = Band.find(band.id)

        if Mongoid::Config.use_utc?
          expect(reloaded.updated.utc?).to be(true)
          expect(reloaded.updated.hour).to eq(9) # 12:00 +03:00 = 09:00 UTC
        end
      end

      it 'preserves timezone conversions after caching' do
        band.save!
        band.updated # First read - caches value
        band.updated # Second read - from cache

        expect(band.updated.utc?).to be(true) if Mongoid::Config.use_utc?
      end
    end

    context 'database persistence' do
      before { band.save! }

      it 'correctly demongoizes fields loaded from database' do
        loaded_band = Band.find(band.id)

        expect(loaded_band.name).to be_a(String)
        expect(loaded_band.tags).to be_a(Hash)
        expect(loaded_band.genres).to be_a(Array)
        expect(loaded_band.rating).to be_a(Float)
        expect(loaded_band.member_count).to be_a(Integer)
        expect(loaded_band.updated).to be_a(Time)
      end

      it 'converts BSON::Document to Hash' do
        loaded_band = Band.find(band.id)

        # MongoDB returns BSON::Document, should be converted to Hash
        expect(loaded_band.tags).to be_a(Hash)
        expect(loaded_band.tags).to eq({ 'genre' => 'rock', 'era' => '80s' })
      end
    end

    context 'cache invalidation' do
      before { band.save! }

      it 'clears cache on reload' do
        band.name = 'Modified Name'
        band.reload
        expect(band.name).to eq('Test Band') # Original value
      end

      it 'handles projector cache when selected_fields change' do
        # Load with different field selections
        limited1 = Band.only(:name).find(band.id)
        limited2 = Band.only(:name, :rating).find(band.id)

        # Both should work correctly with different projections
        expect(limited1.attribute_missing?('rating')).to be(true)
        expect(limited2.attribute_missing?('rating')).to be(false)

        # Projector cache is keyed by selected_fields, so both are cached independently
        expect(limited1.attribute_missing?('rating')).to be(true)
        expect(limited2.attribute_missing?('rating')).to be(false)
      end

      it 'correctly caches nil values' do
        nil_test_class = Class.new do
          include Mongoid::Document
          store_in collection: 'nil_cache_tests'
          field :name, type: String
          field :optional_field, type: String
          field :nullable_int, type: Integer
        end

        stub_const('NilCacheTest', nil_test_class)

        # Create with explicit nil values
        doc = NilCacheTest.create!(name: 'Test', optional_field: nil, nullable_int: nil)

        # First read should cache nil
        expect(doc.optional_field).to be_nil
        expect(doc.nullable_int).to be_nil

        # Second read should return cached nil (not re-demongoize)
        expect(doc.optional_field).to be_nil
        expect(doc.nullable_int).to be_nil

        # Verify zero allocations if available
        if allocation_stats_available
          stats = AllocationStats.trace { 10.times { doc.optional_field } }
          expect(stats.new_allocations.size).to eq(0)
        end

        # Change from nil to value and back to nil
        doc.optional_field = 'something'
        expect(doc.optional_field).to eq('something')

        doc.optional_field = nil
        expect(doc.optional_field).to be_nil

        # Verify cached nil still works
        3.times { expect(doc.optional_field).to be_nil }
      end

      it 'clears cache for written field only' do
        next unless allocation_stats_available

        band.name # cache it
        band.rating # cache it

        band.name = 'New Name' # Only clears name cache

        # rating cache should still work
        stats = AllocationStats.trace { 10.times { band.rating } }
        expect(stats.new_allocations.size).to eq(0)
      end

      it 'gets fresh value after write' do
        band.name # cache it
        original_name = band.name

        band.name = 'New Name'

        expect(band.name).to eq('New Name')
        expect(band.name).not_to eq(original_name)
      end

      it 'clears cache when attribute is removed' do
        band.name # cache it
        expect(band.name).to eq('Test Band')

        band.remove_attribute(:name)

        expect(band.name).to be_nil
      end

      it 'clears cache when attribute is unset' do
        band.name # cache it
        expect(band.name).to eq('Test Band')

        band.unset(:name)

        expect(band.name).to be_nil
      end

      it 'clears cache when field is renamed' do
        band.name # cache it
        expect(band.name).to eq('Test Band')

        band.rename(name: :band_name)

        # Old field should be nil
        expect(band.attributes['name']).to be_nil
        # New field should have the value
        expect(band.attributes['band_name']).to eq('Test Band')
      end

      it 'clears cache when defaults are applied via apply_default' do
        # Test for the fix: apply_default must invalidate cache
        doc_class = Class.new do
          include Mongoid::Document
          store_in collection: 'apply_default_tests'
          field :_id, type: String, overwrite: true, default: -> { name.try(:parameterize) }
          field :name, type: String
        end

        stub_const('ApplyDefaultTest', doc_class)

        # Create document without executing callbacks (simulating build in associations)
        doc = Mongoid::Factory.execute_build(ApplyDefaultTest, { name: 'test value' }, execute_callbacks: false)

        # Reading _id before apply_post_processed_defaults might cache nil
        cached_id = doc._id
        expect(cached_id).to be_nil

        # apply_post_processed_defaults sets the _id
        doc.apply_post_processed_defaults

        # This should return the actual _id, not the cached nil
        # (tests that apply_default invalidates the cache)
        expect(doc._id).to eq('test-value')
        expect(doc._id).not_to be_nil
      end

      it 'tracks changes for resizable fields on every read' do
        # Test for the fix: resizable fields must call attribute_will_change! on every read
        person_class = Class.new do
          include Mongoid::Document
          store_in collection: 'resizable_tracking_tests'
          has_and_belongs_to_many :preferences
        end

        preference_class = Class.new do
          include Mongoid::Document
          store_in collection: 'preferences_tracking_tests'
          field :name, type: String
          has_and_belongs_to_many :people
        end

        stub_const('PersonTracking', person_class)
        stub_const('PreferenceTracking', preference_class)

        person = PersonTracking.create!
        pref = PreferenceTracking.create!(name: 'test')

        # First read - caches the array
        ids = person.preference_ids
        expect(ids).to eq([])

        # Mutate the array (simulating << operator)
        ids << pref.id

        # Person should be marked as changed
        # (tests that attribute_will_change! is called on cached reads)
        expect(person.changed?).to be(true)
        expect(person.changes.keys).to include('preference_ids')
      end

      it 'maintains correct array identity across reads' do
        # Verify that cached arrays maintain object identity (mutations persist)
        person_class = Class.new do
          include Mongoid::Document
          store_in collection: 'array_identity_tests'
          has_and_belongs_to_many :items
        end

        stub_const('PersonArrayIdentity', person_class)

        person = PersonArrayIdentity.create!

        # First read
        arr1 = person.item_ids

        # Mutate it
        test_id = BSON::ObjectId.new
        arr1 << test_id

        # Second read should return same object with mutation
        arr2 = person.item_ids
        expect(arr2.object_id).to eq(arr1.object_id)
        expect(arr2).to include(test_id)
      end
    end

    context 'field projections' do
      before { band.save! }

      it 'works with .only() projection' do
        limited = Band.only(:name, :rating).find(band.id)

        expect(limited.name).to eq('Test Band')
        expect(limited.rating).to eq(8.5)
        expect(limited.attribute_missing?('origin')).to be(true)
      end

      it 'works with .without() projection' do
        limited = Band.without(:tags).find(band.id)

        expect(limited.name).to eq('Test Band')
        expect(limited.attribute_missing?('tags')).to be(true)
      end
    end

    context 'thread safety' do
      it 'handles concurrent field access safely' do
        band = Band.new(name: 'Test Band', rating: 8.5)
        errors = Concurrent::Array.new
        results = Concurrent::Array.new

        threads = Array.new(10) do
          Thread.new do
            100.times do
              name = band.name
              rating = band.rating
              results << [ name, rating ]
            rescue StandardError => e
              errors << e
            end
          end
        end

        threads.each(&:join)
        expect(errors).to be_empty

        # Verify all threads read correct values
        results.each do |name, rating|
          expect(name).to eq('Test Band')
          expect(rating).to eq(8.5)
        end
      end

      it 'handles concurrent projector cache access safely' do
        band = Band.create!(name: 'Test')
        limited = Band.only(:name).find(band.id)
        errors = Concurrent::Array.new

        threads = Array.new(10) do
          Thread.new do
            100.times do
              limited.attribute_missing?('rating')
            rescue StandardError => e
              errors << e
            end
          end
        end

        threads.each(&:join)
        expect(errors).to be_empty
      end
    end

    context 'localized fields' do
      around do |example|
        previous_available_locales = I18n.available_locales
        previous_locale = I18n.locale

        I18n.available_locales = %i[en es]
        I18n.locale = :en

        begin
          example.run
        ensure
          I18n.available_locales = previous_available_locales
          I18n.locale = previous_locale
        end
      end

      it 'does not cache localized fields to preserve i18n behavior' do
        # Create a simple model with localized field using stub_const to avoid test pollution
        localized_band_class = Class.new do
          include Mongoid::Document
          field :title, type: String, localize: true
        end
        stub_const('LocalizedBand', localized_band_class)

        band = LocalizedBand.new
        band.title = 'English Title'

        I18n.locale = :es
        band.title = 'Spanish Title'

        # Verify both locales return correct values
        expect(band.title).to eq('Spanish Title')
        I18n.locale = :en
        expect(band.title).to eq('English Title')

        # Verify repeated reads work correctly (not cached)
        I18n.locale = :es
        3.times { expect(band.title).to eq('Spanish Title') }
        I18n.locale = :en
        3.times { expect(band.title).to eq('English Title') }
      end
    end

    context 'with lazy-settable fields' do
      it 'correctly handles foreign key Array fields with default values' do
        # Create test models with has_and_belongs_to_many relationship
        # This creates a foreign key field with Array type and default: []
        team_class = Class.new do
          include Mongoid::Document
          store_in collection: 'teams'
          field :name, type: String
          has_and_belongs_to_many :players
        end

        player_class = Class.new do
          include Mongoid::Document
          store_in collection: 'players'
          field :name, type: String
          has_and_belongs_to_many :teams
        end

        stub_const('Team', team_class)
        stub_const('Player', player_class)

        team = Team.new(name: 'Test Team')

        # First access triggers lazy evaluation of default value
        expect(team.player_ids).to eq([])

        # Verify the field is properly cached and subsequent access is zero-allocation
        if allocation_stats_available
          team.player_ids # warm up
          stats = AllocationStats.trace { 10.times { team.player_ids } }
          expect(stats.new_allocations.size).to eq(0)
        end
      end

      it 'correctly handles Hash foreign key fields with default values' do
        # Create a model with a Hash-type foreign key field
        metadata_doc_class = Class.new do
          include Mongoid::Document
          store_in collection: 'metadata_docs'
          field :refs, type: Hash, default: -> { {} }
        end

        stub_const('MetadataDoc', metadata_doc_class)

        doc = MetadataDoc.new

        # First access triggers lazy evaluation
        expect(doc.refs).to eq({})

        # Verify proper caching
        if allocation_stats_available
          doc.refs # warm up
          stats = AllocationStats.trace { 10.times { doc.refs } }
          expect(stats.new_allocations.size).to eq(0)
        end
      end

      it 'does not cache before lazy evaluation' do
        team_class = Class.new do
          include Mongoid::Document
          store_in collection: 'teams'
          has_and_belongs_to_many :players
        end

        player_class = Class.new do
          include Mongoid::Document
          store_in collection: 'players'
          has_and_belongs_to_many :teams
        end

        stub_const('Team', team_class)
        stub_const('Player', player_class)

        team = Team.new

        # Before first access, the field should be nil in attributes
        expect(team.attributes['player_ids']).to be_nil

        # First access evaluates and sets the default
        result = team.player_ids
        expect(result).to eq([])

        # Now it should be present in attributes
        expect(team.attributes['player_ids']).to eq([])
      end

      it 'handles modifications to lazy-evaluated fields' do
        team_class = Class.new do
          include Mongoid::Document
          store_in collection: 'teams'
          has_and_belongs_to_many :players
        end

        player_class = Class.new do
          include Mongoid::Document
          store_in collection: 'players'
          field :name, type: String
          has_and_belongs_to_many :teams
        end

        stub_const('Team', team_class)
        stub_const('Player', player_class)

        team = Team.new
        player = Player.new(name: 'John')

        # Lazy evaluation happens on first access
        team.player_ids # => []

        # Modification should work correctly
        team.player_ids << player.id
        expect(team.player_ids).to eq([ player.id ])

        # Cache should be invalidated and re-read correctly
        expect(team.player_ids).to eq([ player.id ])
      end
    end

    context 'atomic operations' do
      it 'invalidates cache on inc operations' do
        atomic_test_class = Class.new do
          include Mongoid::Document
          store_in collection: 'atomic_tests'
          field :counter, type: Integer, default: 0
          field :score, type: Integer, default: 0
        end

        stub_const('AtomicTest', atomic_test_class)

        doc = AtomicTest.new(counter: 10, score: 5)

        # First read to cache the value
        expect(doc.counter).to eq(10)
        expect(doc.score).to eq(5)

        # Perform atomic increment
        doc.inc(counter: 5, score: 3)

        # Verify cache was invalidated and new values are returned
        expect(doc.counter).to eq(15)
        expect(doc.score).to eq(8)

        # Verify repeated reads return correct values (from fresh cache)
        3.times do
          expect(doc.counter).to eq(15)
          expect(doc.score).to eq(8)
        end

        # Verify zero allocations on cached reads if available
        if allocation_stats_available
          stats = AllocationStats.trace { 10.times { doc.counter } }
          expect(stats.new_allocations.size).to eq(0)
        end
      end

      it 'invalidates cache on mul operations' do
        atomic_test_class = Class.new do
          include Mongoid::Document
          store_in collection: 'atomic_mul_tests'
          field :multiplier, type: Integer, default: 1
        end

        stub_const('AtomicMulTest', atomic_test_class)

        doc = AtomicMulTest.new(multiplier: 5)

        # First read to cache the value
        expect(doc.multiplier).to eq(5)

        # Perform atomic multiplication
        doc.mul(multiplier: 3)

        # Verify cache was invalidated and new value is returned
        expect(doc.multiplier).to eq(15)

        # Verify repeated reads return correct value
        3.times { expect(doc.multiplier).to eq(15) }

        # Verify zero allocations on cached reads if available
        if allocation_stats_available
          stats = AllocationStats.trace { 10.times { doc.multiplier } }
          expect(stats.new_allocations.size).to eq(0)
        end
      end

      it 'invalidates cache on bit operations' do
        atomic_test_class = Class.new do
          include Mongoid::Document
          store_in collection: 'atomic_bit_tests'
          field :flags, type: Integer, default: 0
        end

        stub_const('AtomicBitTest', atomic_test_class)

        doc = AtomicBitTest.new(flags: 15) # Binary: 1111

        # First read to cache the value
        expect(doc.flags).to eq(15)

        # Perform atomic bitwise AND operation
        doc.bit(flags: { and: 7 }) # Binary: 0111, result should be 7 (0111)

        # Verify cache was invalidated and new value is returned
        expect(doc.flags).to eq(7)

        # Perform atomic bitwise OR operation
        doc.bit(flags: { or: 8 }) # Binary: 1000, result should be 15 (1111)

        # Verify cache was invalidated and new value is returned
        expect(doc.flags).to eq(15)

        # Verify repeated reads return correct value
        3.times { expect(doc.flags).to eq(15) }

        # Verify zero allocations on cached reads if available
        if allocation_stats_available
          stats = AllocationStats.trace { 10.times { doc.flags } }
          expect(stats.new_allocations.size).to eq(0)
        end
      end
    end
  end
end
# rubocop:enable RSpec/ContextWording, RSpec/ExampleLength
