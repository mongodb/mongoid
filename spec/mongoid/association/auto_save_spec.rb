# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"
require_relative './referenced/has_many_models'
require_relative './referenced/has_one_models'

# Models for the MONGOID-5751 regression test: after_save callbacks must not
# fire for pre-existing, unchanged documents when autosave: true cascades a
# save from a parent to its children.
module AutoSaveMONGOID5751
  class Table
    include Mongoid::Document

    has_many :rows, autosave: true, class_name: 'AutoSaveMONGOID5751::Row',
                    inverse_of: :table

    class << self
      attr_accessor :after_save_count
    end
    self.after_save_count = 0

    after_save { self.class.after_save_count += 1 }
  end

  class Row
    include Mongoid::Document

    belongs_to :table, class_name: 'AutoSaveMONGOID5751::Table', inverse_of: :rows
    has_many :cells, autosave: true, class_name: 'AutoSaveMONGOID5751::Cell',
                     inverse_of: :row

    class << self
      attr_accessor :after_save_count
    end
    self.after_save_count = 0

    after_save { self.class.after_save_count += 1 }
  end

  class Cell
    include Mongoid::Document

    belongs_to :row, class_name: 'AutoSaveMONGOID5751::Row', inverse_of: :cells

    class << self
      attr_accessor :after_save_count
    end
    self.after_save_count = 0

    after_save { self.class.after_save_count += 1 }
  end
end

describe Mongoid::Association::Referenced::AutoSave do

  describe ".auto_save" do

    before(:all) do
      Person.has_many :drugs, validate: false, autosave: true
      Person.has_one :account, validate: false, autosave: true
    end

    after(:all) do
      Person.reset_callbacks(:save)
    end

    let(:person) do
      Person.new
    end

    context "when the option is not provided" do

      context 'has_many' do

        let(:parent) do
          HmmSchool.new
        end

        let(:child) do
          HmmStudent.new(name: "Panda")
        end

        before do
          parent.students = [child]
        end

        context "when saving the parent document" do

          before do
            parent.associations[:students].options[:autosave].should be_falsy

            parent.save!
          end

          it "does not save the child" do
            expect(child).to_not be_persisted
          end
        end
      end

      context 'has_one' do

        let(:parent) do
          HomCollege.new
        end

        let(:child) do
          HomAccreditation.new
        end

        before do
          parent.accreditation = child
        end

        context "when saving the parent document" do

          before do
            parent.associations[:accreditation].options[:autosave].should be_falsy

            parent.save!
          end

          it "does not save the child" do
            expect(child).to_not be_persisted
          end
        end
      end
    end

    context "when the option is true" do

      context "when the relation has already had the autosave callback added" do

        before do
          Person.has_many :drugs, validate: false, autosave: true
        end

        let(:drug) do
          Drug.new(name: "Percocet")
        end

        it "does not add the autosave callback twice" do
          expect(drug).to receive(:save).once
          person.drugs.push(drug)
          person.save!
        end
      end

      context "when the relation is a references many" do

        let(:drug) do
          Drug.new(name: "Percocet")
        end

        context "when saving a new parent document" do

          context 'when persistence options are not set on the parent' do

            before do
              Person.has_many :drugs, validate: false, autosave: true
            end

            before do
              person.drugs << drug
              person.save!
            end

            it "saves the relation" do
              expect(drug).to be_persisted
            end
          end

          context 'when persistence options are set on the parent' do

            let(:other_database) do
              :other
            end

            after do
              Person.with(database: other_database) do |person_class|
                person_class.delete_all
              end
              Drug.with(database: other_database) do |drug_class|
                drug_class.delete_all
              end
            end

            before do
              person.with(database: other_database) do |per|
                per.drugs << drug
                per.save!
              end
            end

            it 'saves the relation with the persistence options' do
              Drug.with(database: other_database) do |drug_class|
                expect(drug_class.count).to eq(1)
              end
            end
          end
        end

        context "when saving an existing parent document" do

          before do
            person.save!
            person.drugs << drug
            person.save!
          end

          it "saves the relation" do
            expect(drug).to be_persisted
          end
        end

        context "when not updating the document" do

          let(:from_db) do
            Person.find person.id
          end

          before do
            person.drugs << drug
            person.save!
          end

          it 'does not load the association' do
            from_db.save!
            expect(from_db.ivar(:drugs)).to be false
          end
        end
      end

      context "when the relation is a references one" do

        let(:account) do
          Account.new(name: "Testing")
        end

        context "when saving a new parent document" do

          before do
            person.account = account
            person.save!
          end

          it "saves the relation" do
            expect(account).to be_persisted
          end

          it "persists on the database" do
            expect(account.reload).to_not be_nil
          end
        end

        context "when saving an existing parent document" do

          before do
            person.save!
            person.account = account
            person.save!
          end

          it "saves the relation" do
            expect(account).to be_persisted
          end

          it "persists on the database" do
            expect(account.reload).to_not be_nil
          end
        end

        context "when updating the child" do

          before do
            person.account = account
            person.save!
          end

          it "sends one insert" do
            account.name = "account"
            expect_query(1) do
              person.with(write: {w:0}) do |_person|
                _person.save!
              end
            end
          end
        end

        context "when not updating the document" do

          let(:from_db) do
            Person.find person.id
          end

          before do
            person.account = account
            person.save!
          end

          it 'does not load the association' do
            from_db.save!
            expect(from_db.ivar(:account)).to be false
          end
        end
      end

      context "when the relation is a referenced in" do

        let(:ghost) do
          Ghost.new(name: "Slimer")
        end

        let(:movie) do
          Movie.new(title: "Ghostbusters")
        end

        context "when saving a new parent document" do

          before do
            ghost.movie = movie
            ghost.save!
          end

          it "saves the relation" do
            expect(movie).to be_persisted
          end
        end

        context "when saving an existing parent document" do

          before do
            ghost.save!
            ghost.movie = movie
            ghost.save!
          end

          it "saves the relation" do
            expect(movie).to be_persisted
          end
        end
      end

      context "when it has two relations with autosaves" do

        let!(:person) do
          Person.create!(drugs: [percocet], account: account)
        end

        let(:from_db) do
          Person.find person.id
        end

        let(:percocet) do
          Drug.new(name: "Percocet")
        end

        let(:account) do
          Account.new(name: "Testing")
        end

        context "when updating one document" do

          let(:placebo) do
            Drug.new(name: "Placebo")
          end

          before do
            from_db.drugs = [placebo]
            from_db.save!
          end

          it 'loads the updated association' do
            expect(from_db.ivar(:drugs)).to eq([placebo])
          end

          it 'doest not load the other association' do
            expect(from_db.ivar(:account)).to be false
          end
        end

        context "when updating none document" do

          before do
            from_db.save!
          end

          it 'doest not load drugs association' do
            expect(from_db.ivar(:drugs)).to be false
          end

          it 'doest not load account association' do
            expect(from_db.ivar(:account)).to be false
          end
        end
      end

      context 'when the autosave should be cascaded' do

        before do
          class King
            include Mongoid::Document
            has_one :peasant, autosave: true
          end

          class Peasant
            include Mongoid::Document
            belongs_to :king
            has_one :harvest, autosave: true
          end

          class Harvest
            include Mongoid::Document
            field :season, type: String
            belongs_to :peasant
          end
        end

        after do
          Object.send(:remove_const, :King)
          Object.send(:remove_const, :Peasant)
          Object.send(:remove_const, :Harvest)
        end

        let(:king) do
          King.create!
        end

        let(:peasant) do
          Peasant.create!
        end

        let(:harvest) do
          Harvest.create!(season: 'Summer')
        end

        before do
          peasant.harvest = harvest
          king.peasant = peasant
          harvest.season = 'Fall'
          king.save!
        end

        it 'cascades the save' do
          expect(harvest.reload.season).to eq('Fall')
        end
      end

      # Regression test for MONGOID-5751: after_save must not fire for
      # pre-existing, unchanged documents that are merely loaded into memory
      # as a side-effect of the autosave traversal.
      context 'when a parent with existing children has a new child added' do
        before do
          # Persist a table with 3 pre-existing rows, each with 3 cells.
          table = AutoSaveMONGOID5751::Table.create!
          3.times do
            row = table.rows.create!
            3.times { row.cells.create! }
          end

          # Reset counters so only the saves triggered by the call below are
          # measured.
          AutoSaveMONGOID5751::Table.after_save_count = 0
          AutoSaveMONGOID5751::Row.after_save_count = 0
          AutoSaveMONGOID5751::Cell.after_save_count = 0

          # Reload the table fresh from the database, then append exactly one
          # new row (with one new cell) and persist.
          reloaded = AutoSaveMONGOID5751::Table.find(table.id)
          new_row = reloaded.rows.build
          new_row.cells.build
          reloaded.save!
        end

        it 'fires after_save once for the parent table' do
          expect(AutoSaveMONGOID5751::Table.after_save_count).to eq(1)
        end

        it 'fires after_save only for the newly added cell' do
          expect(AutoSaveMONGOID5751::Cell.after_save_count).to eq(1)
        end

        context 'when autosave_saves_unchanged_documents is true' do
          config_override :autosave_saves_unchanged_documents, true

          it 'fires after_save for all new and pre-existing rows' do
            expect(AutoSaveMONGOID5751::Row.after_save_count).to eq(4)
          end
        end

        context 'when autosave_saves_unchanged_documents is false' do
          config_override :autosave_saves_unchanged_documents, false

          it 'fires after_save only for the newly added row, not for pre-existing rows' do
            expect(AutoSaveMONGOID5751::Row.after_save_count).to eq(1)
          end
        end
      end
    end
  end
end
