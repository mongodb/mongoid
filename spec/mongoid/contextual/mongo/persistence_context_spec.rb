# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Contextual::Mongo do

  describe "#with" do

    shared_examples 'clears the persistence context' do
      it 'clears the persistence context' do
        # we may have to load the persistence context
        if respond_to?(:persistence_context)
          begin; persistence_context; rescue Mongoid::Errors::InvalidPersistenceOption; end
        end
        expect(criteria.persistence_context).to eq(Mongoid::PersistenceContext.new(Minim))
        expect(criteria.persistence_context?).to be false
      end
    end

    let(:criteria) { Minim.criteria }

    context 'when passing some options' do

      let(:persistence_context) do
        criteria.with(options) do |crit|
          crit.persistence_context
        end
      end

      let(:options) { { database: 'other' } }

      it 'sets the options on the client' do
        expect(persistence_context.client.options['database']).to eq(options[:database])
      end

      it 'does not set the options on class level' do
        expect(criteria.persistence_context.client.options['database']).to eq('mongoid_test')
      end

      context 'when the options are not valid mongo client options' do

        let(:persistence_context) do
          criteria.with(invalid_options) do |crit|
            crit.persistence_context
          end
        end

        let(:invalid_options) { { bad: 'option' } }

        it 'raises an error' do
          expect {
            persistence_context
          }.to raise_exception(Mongoid::Errors::InvalidPersistenceOption)
        end

        include_examples "clears the persistence context"
      end

      context 'when the options include a collection' do

        let(:options) { { collection: 'another-collection' } }

        it 'uses the collection' do
          expect(persistence_context.collection_name).to eq(options[:collection].to_sym)
          expect(persistence_context.collection.name).to eq(options[:collection])
        end

        it 'does not raise an error' do
          expect(persistence_context.client).to be_a(Mongo::Client)
        end

        it 'does not include the collection option in the client options' do
          expect(persistence_context.client.options[:collection]).to be_nil
          expect(persistence_context.client.options['collection']).to be_nil
        end
      end
    end

    context "when changing the collection using #with" do

      context "when calling #with on a criteria" do

        let(:criteria) do
          Band.criteria
        end

        before do
          Band.with(collection: 'artists') do |klass|
            expect(klass.count).to eq(0)
            5.times { klass.create! }
            expect(klass.count).to eq(5)
          end
          expect(Band.count).to eq(0)
        end

        context "when using the block form" do

          it "reads from the correct collection" do
            criteria.with(collection: 'artists') do |crit|
              expect(crit.count).to eq(5)
            end
          end

          it "has the correct persistence context in the block" do
            criteria.with(collection: 'artists') do |crit|
              expect(criteria.persistence_context?).to be true
              expect(criteria.klass.persistence_context?).to be false
            end
          end

          it "doesn't populate klass persistence context" do
            expect(Band.persistence_context?).to be false
          end

          include_examples "clears the persistence context"
        end

        context "when not using blocks" do

          let!(:criteria) do
            Band.criteria.with(collection: 'artists')
          end

          it "reads correctly" do
            expect(criteria.count).to eq(5)
          end

          it "doesn't populate klass persistence context" do
            expect(criteria.persistence_context?).to be true
            expect(Band.persistence_context?).to be false
          end
        end
      end

      context "when calling #with on the klass" do

        before do
          Band.with(collection: 'artists') do |klass|
            expect(klass.count).to eq(0)
            5.times { klass.create! }
            expect(klass.count).to eq(5)
          end
          expect(Band.count).to eq(0)
        end

        context "when using the block form" do

          it "reads from the correct collection" do
            Band.with(collection: "artists") do |klass|
              expect(klass.count).to eq(5)
            end
          end

          it "has the correct persistence context in the block" do
            Band.with(collection: "artists") do |klass|
              expect(klass.persistence_context?).to be true
            end
          end

          it "clears the klass persistence context" do
            expect(Band.persistence_context?).to be false
          end

          include_examples "clears the persistence context"
        end

        context "when not using block form" do

          let!(:criteria) { Band.with(collection: 'artists') }

          it "returns a criteria" do
            expect(criteria).to be_a(Mongoid::Criteria)
          end

          it "reads from the correct collection" do
            expect(criteria.count).to eq(5)
          end

          it "has the persistence context in the criteria" do
            expect(criteria.persistence_context?).to be true
          end

          it "doesn't populate klass persistence context" do
            expect(Band.persistence_context?).to be false
          end
        end

        context "when using an old criteria" do

          let(:old_criteria) do
            Band.all.tap do |crit|
              crit.view # load the view
            end
          end

          let(:criteria) do
            old_criteria.with(collection: 'artists')
          end

          it "reads from the correct collection" do
            expect(criteria.count).to eq(5)
          end

          it "creates a new criteria" do
            expect(old_criteria).to_not be(criteria)
          end
        end
      end

      context "when calling #with on a document" do

        let(:band) { Band.new }

        before do
          expect(Band.count).to eq(0)
        end

        context "when using the block form" do

          before do
            band.with(collection: "artists") do |band|
              band.save
            end
            expect(Band.count).to eq(0)
          end

          it "reads from the correct collection" do
            Band.with(collection: "artists") do |klass|
              expect(klass.count).to eq(1)
              expect(klass.first).to eq(band)
            end
          end

          it "has the correct persistence context in the block" do
            band.with(collection: "artists") do |doc|
              expect(doc.persistence_context?).to be true
              expect(doc.class.persistence_context?).to be false
            end
          end

          it "clears the persistence context" do
            expect(band.persistence_context?).to be false
          end

          it "doesn't populate klass persistence context" do
            expect(Band.persistence_context?).to be false
          end
        end

        context "when not using block form" do

          let(:band) { Band.new.with(collection: "artists") }

          before do
            band.save
            expect(Band.count).to eq(0)
          end

          it "reads from the correct collection" do
            Band.with(collection: "artists") do |klass|
              expect(klass.count).to eq(1)
              expect(klass.first).to eq(band)
            end
          end

          it "has a persistence context" do
            expect(band.persistence_context?).to be true
          end

          it "doesn't populate klass persistence context" do
            expect(Band.persistence_context?).to be false
          end
        end
      end
    end

    context "when setting the database" do

      context "when calling #with on a criteria" do

        let(:criteria) do
          Band.criteria
        end

        before do
          Band.with(database: database_id_alt) do |klass|
            klass.destroy_all
            expect(klass.count).to eq(0)
            5.times { klass.create! }
            expect(klass.count).to eq(5)
          end
          expect(Band.count).to eq(0)
        end

        context "when using the block form" do

          it "reads from the correct database" do
            criteria.with(database: database_id_alt) do |crit|
              expect(crit.count).to eq(5)
            end
          end
        end

        context "when not using blocks" do

          let!(:criteria) do
            Band.criteria.with(database: database_id_alt)
          end

          it "reads correctly" do
            expect(criteria.count).to eq(5)
          end
        end
      end

      context "when calling #with on the klass" do

        before do
          Band.with(database: database_id_alt) do |klass|
            klass.destroy_all
            expect(klass.count).to eq(0)
            5.times { klass.create! }
            expect(klass.count).to eq(5)
          end
          expect(Band.count).to eq(0)
        end

        context "when using the block form" do

          it "reads from the correct database" do
            Band.with(database: database_id_alt) do |klass|
              expect(klass.count).to eq(5)
            end
          end
        end

        context "when not using block form" do

          let!(:criteria) { Band.with(database: database_id_alt) }

          it "reads from the correct database" do
            expect(criteria.count).to eq(5)
          end
        end

        context "when using an old criteria" do

          let(:criteria) do
            crit = Band.all
            crit.view # load the view
            crit.with(database: database_id_alt)
          end

          it "reads from the correct database" do
            expect(criteria.count).to eq(5)
          end
        end
      end

      context "when calling #with on a document" do

        let(:band) { Band.new }

        before do
          Band.with(database: database_id_alt) do |klass|
            klass.destroy_all
            expect(klass.count).to eq(0)
          end
          expect(Band.count).to eq(0)
        end

        context "when using the block form" do

          before do
            band.with(database: database_id_alt) do |band|
              band.save
            end
            expect(Band.count).to eq(0)
          end

          it "reads from the correct database" do
            Band.with(database: database_id_alt) do |klass|
              expect(klass.count).to eq(1)
              expect(klass.first).to eq(band)
            end
          end
        end

        context "when not using block form" do

          let(:band) { Band.new.with(database: database_id_alt) }

          before do
            band.save
            expect(Band.count).to eq(0)
          end

          it "reads from the correct database" do
            Band.with(database: database_id_alt) do |klass|
              expect(klass.count).to eq(1)
              expect(klass.first).to eq(band)
            end
          end
        end
      end
    end
  end

  # describe "#clear_persistence_context!" do

  #   context "when calling on a criteria" do
  #     let(:criteria) { Band.with(collection: "artists") }

  #     before do
  #       expect(criteria.persistence_context?).to be true
  #     end

  #     it "clears the persistence context" do
  #       criteria.clear_persistence_context!
  #       expect(criteria.persistence_context?).to be false
  #     end
  #   end

  #   context "when calling on a document" do

  #     let(:band) { Band.new.with(collection: "artists") }

  #     before do
  #       expect(band.persistence_context?).to be true
  #     end

  #     it "clears the persistence context" do
  #       band.clear_persistence_context!
  #       expect(band.persistence_context?).to be false
  #     end
  #   end

  #   context "when there is no persistence context" do

  #     before do
  #       expect(Band.persistence_context?).to be false
  #     end

  #     it "clears the persistence context" do
  #       Band.clear_persistence_context!
  #       expect(Band.persistence_context?).to be false
  #     end
  #   end
  # end
end
