# frozen_string_literal: true

require "spec_helper"
require_relative './interceptable_spec_models'

describe Mongoid::Interceptable do

  before do
    # The find and initialize callbacks I added were causing failures
    # because they were causing updates when we were asserting no updates
    # happened.
    Label.reset_callbacks(:initialize)
    Label.reset_callbacks(:find)
  end

  class TestClass
    include Mongoid::Interceptable

    attr_reader :before_save_called, :after_save_called

    before_save do |object|
      @before_save_called = true
    end

    after_save do |object|
      @after_save_called = true
    end
  end

  describe ".included" do

    let(:klass) do
      TestClass
    end

    it "includes the before_create callback" do
      expect(klass).to respond_to(:before_create)
    end

    it "includes the after_create callback" do
      expect(klass).to respond_to(:after_create)
    end

    it "includes the before_destroy callback" do
      expect(klass).to respond_to(:before_destroy)
    end

    it "includes the after_destroy callback" do
      expect(klass).to respond_to(:after_destroy)
    end

    it "includes the before_save callback" do
      expect(klass).to respond_to(:before_save)
    end

    it "includes the after_save callback" do
      expect(klass).to respond_to(:after_save)
    end

    it "includes the before_update callback" do
      expect(klass).to respond_to(:before_update)
    end

    it "includes the after_update callback" do
      expect(klass).to respond_to(:after_update)
    end

    it "includes the before_validation callback" do
      expect(klass).to respond_to(:before_validation)
    end

    it "includes the after_validation callback" do
      expect(klass).to respond_to(:after_validation)
    end

    it "includes the after_initialize callback" do
      expect(klass).to respond_to(:after_initialize)
    end

    it "includes the after_build callback" do
      expect(klass).to respond_to(:after_build)
    end
  end

  describe ".after_find" do

    let!(:player) do
      Player.create!
    end

    context "when the callback is on a root document" do

      context "when when the document is instantiated" do

        it "does not execute the callback" do
          expect(player.impressions).to eq(0)
        end
      end

      context "when the document is found via #find" do

        let(:from_db) do
          Player.find(player.id)
        end

        it "executes the callback" do
          expect(from_db.impressions).to eq(1)
        end
      end

      context "when the document is found in a criteria" do

        let(:from_db) do
          Player.where(id: player.id).first
        end

        it "executes the callback" do
          expect(from_db.impressions).to eq(1)
        end
      end

      context "when the document is reloaded" do

        let(:from_db) do
          Player.find(player.id)
        end

        before do
          from_db.reload
        end

        it "executes the callback" do
          expect(from_db.impressions).to eq(1)
        end
      end
    end

    context "when the callback is on an embedded document" do

      let!(:implant) do
        player.implants.create!
      end

      context "when when the document is instantiated" do

        it "does not execute the callback" do
          expect(implant.impressions).to eq(0)
        end
      end

      context "when the document is found via #find" do

        let(:from_db) do
          Player.find(player.id).implants.first
        end

        it "executes the callback" do
          expect(from_db.impressions).to eq(1)
        end
      end

      context "when the document is found in a criteria" do

        let(:from_db) do
          Player.find(player.id).implants.find(implant.id)
        end

        it "executes the callback" do
          expect(from_db.impressions).to eq(1)
        end
      end
    end
  end

  describe ".after_initialize" do

    let(:game) do
      Game.new
    end

    it "runs after document instantiation" do
      expect(game.name).to eq("Testing")
    end

    context 'when the document is embedded' do

      after do
        Book.destroy_all
      end

      let(:book) do
        book = Book.new({
          :pages => [
            {
              content: "Page 1",
              notes: [
                { message: "Page 1 / Note A" },
                { message: "Page 1 / Note B" }
              ]
            },
            {
              content: "Page 2",
              notes: [
                { message: "Page 2 / Note A" },
                { message: "Page 2 / Note B" }
              ]
            }
          ]
        })
        book.id = '123'
        book.save!
        book
      end

      let(:new_message) do
        'Note C'
      end

      before do
        book.pages.each do | page |
          page.notes.destroy_all
          page.notes.new(message: new_message)
          page.save!
        end
      end

      let(:expected_messages) do
        book.reload.pages.reduce([]) do |messages, p|
          messages += p.notes.reduce([]) do |msgs, n|
            msgs << n.message
          end
        end
      end

      it 'runs the callback on the embedded documents and saves the parent document' do
        expect(expected_messages.all? { |m| m == new_message }).to be(true)
      end
    end
  end

  describe ".after_build" do

    let(:weapon) do
      Player.new(frags: 5).weapons.build
    end

    it "runs after document build (references_many)" do
      expect(weapon.name).to eq("Holy Hand Grenade (5)")
    end

    let(:implant) do
      Player.new(frags: 5).implants.build
    end

    it "runs after document build (embeds_many)" do
      expect(implant.name).to eq('Cochlear Implant (5)')
    end

    let(:powerup) do
      Player.new(frags: 5).build_powerup
    end

    it "runs after document build (references_one)" do
      expect(powerup.name).to eq("Quad Damage (5)")
    end

    let(:augmentation) do
      Player.new(frags: 5).build_augmentation
    end

    it "runs after document build (embeds_one)" do
      expect(augmentation.name).to eq("Infolink (5)")
    end
  end

  describe ".before_create" do

    let(:artist) do
      Artist.new(name: "Depeche Mode")
    end

    context "callback returns true" do

      before do
        expect(artist).to receive(:before_create_stub).once.and_return(true)
        artist.save!
      end

      it "gets saved" do
        expect(artist.persisted?).to be true
      end
    end

    context "callback aborts the callback chain" do

      before do
        Artist.before_create(:before_create_fail_stub)
        expect(artist).to receive(:before_create_fail_stub).once.and_call_original
        artist.save
      end

      after do
        Artist.reset_callbacks(:create)
      end

      it "does not get saved" do
        expect(artist.persisted?).to be false
      end
    end
  end

  describe ".before_save" do

    context "when creating" do

      let(:artist) do
        Artist.new(name: "Depeche Mode")
      end

      after do
        artist.delete
      end

      context "when the callback returns true" do

        before do
          expect(artist).to receive(:before_save_stub).once.and_return(true)
        end

        it "the save returns true" do
          expect(artist.save!).to be true
        end
      end

      context "when callback halts the callback chain" do

        before do
          Artist.before_save(:before_save_fail_stub)
        end

        after do
          Artist.reset_callbacks(:save)
        end

        it "the save returns false" do
          expect(artist).to receive(:before_save_fail_stub).once.and_call_original
          expect(artist.save).to be false
        end
      end
    end

    context "when updating" do

      let(:artist) do
        Artist.create!(name: "Depeche Mode").tap do |artist|
          artist.name = "The Mountain Goats"
        end
      end

      after do
        artist.delete
      end

      context "when the callback returns true" do

        before do
          expect(artist).to receive(:before_update_stub).once.and_return(true)
        end

        it "the save returns true" do
          expect(artist.save!).to be true
        end
      end

      context "when the callback halts the callback chain" do

        before do
          Artist.before_update(:before_update_fail_stub)
        end

        after do
          Artist.reset_callbacks(:update)
        end

        it "the save returns false" do
          expect(artist).to receive(:before_update_fail_stub).once.and_call_original
          expect(artist.save).to be false
        end
      end
    end
  end

  describe ".before_destroy" do

    let(:artist) do
      Artist.create!(name: "Depeche Mode")
    end

    before do
      artist.name = "The Mountain Goats"
    end

    after do
      artist.delete
    end

    context "when the callback returns true" do

      before do
        expect(artist).to receive(:before_destroy_stub).once.and_return(true)
      end

      it "the destroy returns true" do
        expect(artist.destroy).to be true
      end
    end

    context "when the callback halts the callback chain" do

      before do
        Artist.before_destroy(:before_destroy_fail_stub)
      end

      after do
        Artist.reset_callbacks(:destroy)
      end

      it "the destroy returns false" do
        expect(artist).to receive(:before_destroy_fail_stub).once.and_call_original
        expect(artist.destroy).to be false
      end
    end

    context "when cascading callbacks" do

      let!(:moderat) do
        Band.create!(name: "Moderat")
      end

      let!(:record) do
        moderat.records.create!(name: "Moderat")
      end

      before do
        moderat.destroy
      end

      it "executes the child destroy callbacks" do
        expect(record.before_destroy_called).to be true
      end
    end
  end

  describe "#run_after_callbacks" do

    let(:object) do
      TestClass.new
    end

    before do
      object.run_after_callbacks(:save)
    end

    it "runs the after callbacks" do
      expect(object.after_save_called).to be true
    end

    it "does not run the before callbacks" do
      expect(object.before_save_called).to be nil
    end
  end

  describe "#run_before_callbacks" do

    let(:object) do
      TestClass.new
    end

    before do
      object.run_before_callbacks(:save)
    end

    it "runs the before callbacks" do
      expect(object.before_save_called).to be true
    end

    it "does not run the after callbacks" do
      expect(object.after_save_called).to be nil
    end
  end

  context "when cascading callbacks" do

    context "when the parent has a custom callback" do

      context "when the child does not have the same callback defined" do

        let(:exhibition) do
          Exhibition.new
        end

        let!(:exhibitor) do
          exhibition.exhibitors.build
        end

        context "when running the callbacks directly" do

          before(:all) do
            Exhibition.define_model_callbacks(:rearrange)
            Exhibition.after_rearrange { }
          end

          after(:all) do
            Exhibition.reset_callbacks(:rearrange)
          end

          it "does not cascade to the child" do
            expect(exhibition.run_callbacks(:rearrange)).to be true
          end
        end

        context "when the callbacks get triggered by a destroy" do

          let(:band) do
            Band.new
          end

          let!(:record) do
            band.records.build
          end

          before(:all) do
            Band.define_model_callbacks(:rearrange)
            Band.set_callback(:validation, :before) do
              run_callbacks(:rearrange)
            end
          end

          after(:all) do
            # ActiveSupport may raise an error when trying to reset callbacks on all of Band's
            # descendants, regardless of whether they have a particular callback defined.
            begin; Band.reset_callbacks(:rearrange); rescue; end
          end

          let(:attributes) do
            {
              records_attributes: {
                "0" => { "_id" => record.id, "_destroy" => true }
              }
            }
          end

          it "does not cascade to the child" do
            Band.accepts_nested_attributes_for :records, allow_destroy: true
            expect(band.update_attributes!(attributes)).to be true
          end
        end
      end
    end

    context "when a document can exist in more than 1 level" do

      let(:band) do
        Band.new
      end

      let(:record) do
        band.records.build
      end

      let(:note) do
        Note.new
      end

      context "when adding the document at multiple levels" do

        before do
          band.notes.push(note)
          record.notes.push(note)
        end

        context "when saving the root" do
          context 'with prevent_multiple_calls_of_embedded_callbacks enabled' do
            config_override :prevent_multiple_calls_of_embedded_callbacks, true

            it "executes the callbacks only once for each document" do
              expect(note).to receive(:update_saved).once
              band.save!
            end
          end

          context 'with prevent_multiple_calls_of_embedded_callbacks disabled' do
            config_override :prevent_multiple_calls_of_embedded_callbacks, false

            it "executes the callbacks once for each ember" do
              expect(note).to receive(:update_saved).twice
              band.save!
            end
          end
        end
      end
    end

    context "when cascading after initialize" do

      let!(:person) do
        Person.create!
      end

      before do
        person.services.create!(sid: 1)
      end

      it "doesn't cascade the initialize" do
        expect_any_instance_of(Service).to receive(:after_initialize_called=).never
        expect(Person.find(person.id)).to eq(person)
      end
    end

    context "when attempting to cascade on a referenced relation" do

      it "raises an error" do
        expect {
          Band.has_and_belongs_to_many :tags, cascade_callbacks: true
        }.to raise_error(Mongoid::Errors::InvalidRelationOption)
      end
    end

    context "when the documents are embedded one level" do

      describe "#after_create" do

        context "when the child is new" do

          context "when the parent is new" do

            let(:band) do
              Band.new(name: "Moderat")
            end

            let!(:label) do
              band.build_label(name: "Mute")
            end

            before do
              band.save!
            end

            it "executes the callback" do
              expect(label.after_create_called).to be true
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create!(name: "Moderat")
            end

            let!(:label) do
              band.build_label(name: "Mute")
            end

            before do
              band.save!
            end

            it "executes the callback" do
              expect(label.after_create_called).to be true
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create!(name: "Moderat")
          end

          let!(:label) do
            band.create_label(name: "Mute")
          end

          before do
            label.after_create_called = false
            band.save!
          end

          it "does not execute the callback" do
            expect(label.after_create_called).to be false
          end
        end
      end

      describe "#after_save" do

        context "when the child is new" do

          context "when the parent is new" do

            let(:band) do
              Band.new(name: "Moderat")
            end

            let!(:label) do
              band.build_label(name: "Mute")
            end

            before do
              band.save!
            end

            it "executes the callback" do
              expect(label.after_save_called).to be true
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create!(name: "Moderat")
            end

            let!(:label) do
              band.build_label(name: "Mute")
            end

            before do
              band.save!
            end

            it "executes the callback" do
              expect(label.after_save_called).to be true
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create!(name: "Moderat")
          end

          let!(:label) do
            band.create_label(name: "Mute")
          end

          before do
            band.save!
          end

          it "executes the callback" do
            expect(label.after_save_called).to be true
          end
        end
      end

      describe "#after_update" do

        context "when the child is new" do

          context "when the parent is new" do

            let(:band) do
              Band.new(name: "Moderat")
            end

            let!(:label) do
              band.build_label(name: "Mute")
            end

            before do
              band.save!
            end

            it "does not execute the callback" do
              expect(label.after_update_called).to be false
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create!(name: "Moderat")
            end

            let!(:label) do
              band.build_label(name: "Mute")
            end

            before do
              band.save!
            end

            it "does not execute the callback" do
              expect(label.after_update_called).to be false
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create!(name: "Moderat")
          end

          context "when the child is dirty" do

            let!(:label) do
              band.create_label(name: "Mute")
            end

            before do
              label.name = "Nothing"
              band.save!
            end

            it "executes the callback" do
              expect(label.after_update_called).to be true
            end
          end

          context "when the child is not dirty" do

            let!(:label) do
              band.build_label(name: "Mute")
            end

            before do
              band.save!
            end

            it "does not execute the callback" do
              expect(label.after_update_called).to be false
            end
          end
        end
      end

      describe "#after_validation" do

        context "when the child is new" do

          context "when the parent is new" do

            let(:band) do
              Band.new(name: "Moderat")
            end

            let!(:label) do
              band.build_label(name: "Mute")
            end

            before do
              band.save!
            end

            it "executes the callback" do
              expect(label.after_validation_called).to be true
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create!(name: "Moderat")
            end

            let!(:label) do
              band.build_label(name: "Mute")
            end

            before do
              band.save!
            end

            it "executes the callback" do
              expect(label.after_validation_called).to be true
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create!(name: "Moderat")
          end

          let!(:label) do
            band.create_label(name: "Mute")
          end

          before do
            band.save!
          end

          it "executes the callback" do
            expect(label.after_validation_called).to be true
          end
        end
      end

      describe "#before_create" do

        context "when the child is new" do

          context "when the parent is new" do

            let(:band) do
              Band.new(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            before do
              band.save!
            end

            it "executes the callback" do
              expect(record.before_create_called).to be true
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create!(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            before do
              band.save!
            end

            it "executes the callback" do
              expect(record.before_create_called).to be true
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create!(name: "Moderat")
          end

          let!(:record) do
            band.records.create!(name: "Moderat")
          end

          before do
            record.before_create_called = false
            band.save!
          end

          it "does not execute the callback" do
            expect(record.before_create_called).to be false
          end
        end
      end

      describe "#before_save" do

        context "when the child is new" do

          context "when the parent is new" do

            let(:band) do
              Band.new(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            before do
              band.save!
            end

            it "executes the callback" do
              expect(record.before_save_called).to be true
            end

            it "persists the change" do
              expect(band.reload.records.first.before_save_called).to be true
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create!(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            before do
              band.save!
            end

            it "executes the callback" do
              expect(record.before_save_called).to be true
            end

            it "persists the change" do
              expect(band.reload.records.first.before_save_called).to be true
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create!(name: "Moderat")
          end

          let!(:record) do
            band.records.create!(name: "Moderat")
          end

          before do
            band.save!
          end

          it "executes the callback" do
            expect(record.before_save_called).to be true
          end

          it "persists the change" do
            expect(band.reload.records.first.before_save_called).to be true
          end
        end

        context "when the child is created" do

          let!(:band) do
            Band.create!
          end

          let!(:label) do
            band.create_label(name: 'Label')
          end

          it "only executes callback once" do
            expect(label.before_save_count).to be 1
          end
        end
      end

      describe "#before_update" do

        context "when the child is new" do

          context "when the parent is new" do

            let(:band) do
              Band.new(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            before do
              band.save!
            end

            it "does not execute the callback" do
              expect(record.before_update_called).to be false
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create!(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            before do
              band.save!
            end

            it "does not execute the callback" do
              expect(record.before_update_called).to be false
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create!(name: "Moderat")
          end

          let!(:record) do
            band.records.create!(name: "Moderat")
          end

          context "when the child is dirty" do

            before do
              record.name = "Nothing"
              band.save!
            end

            it "executes the callback" do
              expect(record.before_update_called).to be true
            end

            it "persists the change" do
              expect(band.reload.records.first.before_update_called).to be true
            end
          end

          context "when the child is not dirty" do

            before do
              band.save!
            end

            it "does not execute the callback" do
              expect(record.before_update_called).to be false
            end
          end
        end
      end

      describe "#before_validation" do

        context "when the child is new" do

          context "when the parent is new" do

            let(:band) do
              Band.new(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            before do
              band.save!
            end

            it "executes the callback" do
              expect(record.before_validation_called).to be true
            end

            it "persists the change" do
              expect(band.reload.records.first.before_validation_called).to be true
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create!(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            before do
              band.save!
            end

            it "executes the callback" do
              expect(record.before_validation_called).to be true
            end

            it "persists the change" do
              expect(band.reload.records.first.before_validation_called).to be true
            end
          end

          context 'when the parent is updated' do

            let(:band) do
              Band.create!(name: "Moderat")
            end

            before do
              band.update(records: [ { name: 'Black on Both Sides' }])
            end

            it 'executes the callback' do
              expect(band.records.first.before_validation_called).to be true
            end

            it 'persists the change' do
              expect(band.reload.records.first.before_validation_called).to be true
            end
          end
        end

        context 'when the parent is updated' do

          let(:band) do
            Band.create!(name: "Moderat")
          end

          before do
            band.update(records: [ { name: 'Black on Both Sides' }])
          end

          it 'executes the callback' do
            expect(band.records.first.before_validation_called).to be true
          end

          it 'persists the change' do
            expect(band.reload.records.first.before_validation_called).to be true
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create!(name: "Moderat")
          end

          let!(:record) do
            band.records.create!(name: "Moderat")
          end

          before do
            band.save!
          end

          it "executes the callback" do
            expect(record.before_validation_called).to be true
          end

          it "persists the change" do
            expect(band.reload.records.first.before_validation_called).to be true
          end
        end
      end
    end

    context "when the document is embedded multiple levels" do

      describe "#before_create" do

        context "when the child is new" do

          context "when the root is new" do

            let(:band) do
              Band.new(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            let!(:track) do
              record.tracks.build(name: "Berlin")
            end

            before do
              band.save!
            end

            it "executes the callback" do
              expect(track.before_create_called).to be true
            end
          end

          context "when the root is persisted" do

            let(:band) do
              Band.create!(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            let!(:track) do
              record.tracks.build(name: "Berlin")
            end

            before do
              band.save!
            end

            it "executes the callback" do
              expect(track.before_create_called).to be true
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create!(name: "Moderat")
          end

          let!(:record) do
            band.records.create!(name: "Moderat")
          end

          let!(:track) do
            record.tracks.create!(name: "Berlin")
          end

          before do
            track.before_create_called = false
            band.save!
          end

          it "does not execute the callback" do
            expect(track.before_create_called).to be false
          end
        end
      end

      describe "#before_save" do

        context "when the child is new" do

          context "when the root is new" do

            let(:band) do
              Band.new(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            let!(:track) do
              record.tracks.build(name: "Berlin")
            end

            before do
              band.save!
            end

            let(:reloaded) do
              band.reload.records.first
            end

            it "executes the callback" do
              expect(track.before_save_called).to be true
            end

            it "persists the change" do
              expect(reloaded.tracks.first.before_save_called).to be true
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create!(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            let!(:track) do
              record.tracks.build(name: "Berlin")
            end

            before do
              band.save!
            end

            let(:reloaded) do
              band.reload.records.first
            end

            it "executes the callback" do
              expect(track.before_save_called).to be true
            end

            it "persists the change" do
              expect(reloaded.tracks.first.before_save_called).to be true
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create!(name: "Moderat")
          end

          let!(:record) do
            band.records.create!(name: "Moderat")
          end

          let!(:track) do
            record.tracks.create!(name: "Berlin")
          end

          before do
            band.save!
          end

          let(:reloaded) do
            band.reload.records.first
          end

          it "executes the callback" do
            expect(track.before_save_called).to be true
          end

          it "persists the change" do
            expect(reloaded.tracks.first.before_save_called).to be true
          end
        end
      end

      describe "#before_update" do

        context "when the child is new" do

          context "when the parent is new" do

            let(:band) do
              Band.new(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            let!(:track) do
              record.tracks.build(name: "Berlin")
            end

            before do
              band.save!
            end

            it "does not execute the callback" do
              expect(track.before_update_called).to be false
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create!(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            let!(:track) do
              record.tracks.build(name: "Berlin")
            end

            before do
              band.save!
            end

            it "does not execute the callback" do
              expect(track.before_update_called).to be false
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create!(name: "Moderat")
          end

          let!(:record) do
            band.records.create!(name: "Moderat")
          end

          let!(:track) do
            record.tracks.create!(name: "Berlin")
          end

          context "when the child is dirty" do

            before do
              track.name = "Rusty Nails"
              band.save!
            end

            let(:reloaded) do
              band.reload.records.first
            end

            it "executes the callback" do
              expect(track.before_update_called).to be true
            end

            it "persists the change" do
              expect(reloaded.tracks.first.before_update_called).to be true
            end
          end

          context "when the child is not dirty" do

            before do
              band.save!
            end

            it "does not execute the callback" do
              expect(track.before_update_called).to be false
            end
          end
        end
      end

      describe '#after_destroy' do

        context 'when the parent is updated in a child after_destroy callback' do

          let!(:person) do
            Person.create!(ordered_posts: [OrderedPost.new])
          end

          before do
            post = OrderedPost.first
            post.destroy
          end

          it 'updates the parent' do
            expect(person.reload.title).to eq('Minus one ordered post.')
          end
        end
      end

      describe "#before_validation" do

        context "when the child is new" do

          context "when the parent is new" do

            let(:band) do
              Band.new(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            let!(:track) do
              record.tracks.build(name: "Berlin")
            end

            before do
              band.save!
            end

            it "executes the callback" do
              expect(track.before_validation_called).to be true
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create!(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            let!(:track) do
              record.tracks.build(name: "Berlin")
            end

            before do
              band.save!
            end

            it "executes the callback" do
              expect(track.before_validation_called).to be true
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create!(name: "Moderat")
          end

          let!(:record) do
            band.records.create!(name: "Moderat")
          end

          let!(:track) do
            record.tracks.create!(name: "Berlin")
          end

          before do
            band.save!
          end

          it "executes the callback" do
            expect(track.before_validation_called).to be true
          end
        end
      end
    end
  end

  context "callback on valid?" do

    it "goes in all validation callback in good order" do
      shin = ValidationCallback.new
      shin.valid?
      expect(shin.history).to eq([:before_validation, :validate, :after_validation])
    end
  end

  context "when creating child documents in callbacks" do

    let(:parent) do
      ParentDoc.new
    end

    before do
      parent.save!
    end

    it "does not duplicate the child documents" do
      parent.children.create!(position: 1)
      expect(ParentDoc.find(parent.id).children.size).to eq(1)
    end
  end

  context "when callbacks cancel persistence" do

    let(:address) do
      Address.new(street: "123 Sesame")
    end

    before(:all) do
      Person.before_save do |doc|
        throw(:abort) if doc.mode == :prevent_save
      end
    end

    after(:all) do
      Person.reset_callbacks(:save)
    end

    context "when creating a document" do

      let(:person) do
        Person.new(mode: :prevent_save, title: "Associate", addresses: [ address ])
      end

      it "fails to save" do
        expect(person).to be_valid
        expect(person.save).to be false
      end

      it "is a new record" do
        expect(person).to be_a_new_record
        expect { person.save }.not_to change { person.new_record? }
      end

      it "is left dirty" do
        expect(person).to be_changed
        expect { person.save }.not_to change { person.changed? }
      end

      it "child documents are left dirty" do
        expect(address).to be_changed
        expect { person.save }.not_to change { address.changed? }
      end
    end

    context "when updating a document" do

      let(:person) do
        Person.create!.tap do |person|
          person.attributes = {
            mode: :prevent_save,
            title: "Associate",
            addresses: [ address ]
          }
        end
      end

      it "#save returns false" do
        expect(person).to be_valid
        expect(person.save).to be false
      end

      it "is a not a new record" do
        expect(person).to_not be_a_new_record
        expect { person.save }.not_to change { person.new_record? }
      end

      it "is left dirty" do
        expect(person).to be_changed
        expect { person.save }.not_to change { person.changed? }
      end

      it "child documents are left dirty" do
        expect(address).to be_changed
        expect { person.save }.not_to change { address.changed? }
      end
    end
  end

  context "when loading a model multiple times" do

    before do
      load File.join(MODELS, "callback_test.rb")
      load File.join(MODELS, "callback_test.rb")
    end

    let(:callback) do
      CallbackTest.new
    end

    context "when saving the document" do

      it "only executes the callbacks once" do
        expect(callback).to receive(:execute).once
        callback.save
      end
    end
  end

  context 'when creating a parent and embedded child' do
    let(:registry) { InterceptableSpec::CallbackRegistry.new }
    let(:parent) do
      InterceptableSpec::CbParent.new(registry).tap do |parent|
        parent.cb_children << InterceptableSpec::CbChild.new(registry, cb_parent: parent)
      end
    end

    let(:expected) do
      [
        [InterceptableSpec::CbParent, :before_validation],
        [InterceptableSpec::CbChild, :before_validation],
        [InterceptableSpec::CbChild, :after_validation],
        [InterceptableSpec::CbParent, :after_validation],
        [InterceptableSpec::CbParent, :before_save],
        [InterceptableSpec::CbParent, :around_save_open],
        [InterceptableSpec::CbParent, :before_create],
        [InterceptableSpec::CbParent, :around_create_open],
        [InterceptableSpec::CbParent, :around_create_close],
        [InterceptableSpec::CbParent, :after_create],
        [InterceptableSpec::CbParent, :around_save_close],
        [InterceptableSpec::CbParent, :after_save],
      ]
    end

    it 'calls callbacks in the right order' do
      parent.save!
      expect(registry.calls).to eq expected
    end
  end

  context 'when creating a parent and embedded child with cascading callbacks' do
    let(:registry) { InterceptableSpec::CallbackRegistry.new }
    let(:parent) do
      InterceptableSpec::CbParent.new(registry).tap do |parent|
        parent.cb_cascaded_children <<
          InterceptableSpec::CbCascadedChild.new(registry, cb_parent: parent)
      end
    end

    let(:expected) do
      [
        [InterceptableSpec::CbCascadedChild, :before_validation],
        [InterceptableSpec::CbCascadedChild, :after_validation],
        [InterceptableSpec::CbParent, :before_validation],
        [InterceptableSpec::CbCascadedChild, :before_validation],
        [InterceptableSpec::CbCascadedChild, :after_validation],

        [InterceptableSpec::CbParent, :after_validation],
        [InterceptableSpec::CbParent, :before_save],
        [InterceptableSpec::CbParent, :around_save_open],
        [InterceptableSpec::CbParent, :before_create],
        [InterceptableSpec::CbParent, :around_create_open],

        [InterceptableSpec::CbCascadedChild, :before_save],
        [InterceptableSpec::CbCascadedChild, :around_save_open],
        [InterceptableSpec::CbCascadedChild, :before_create],
        [InterceptableSpec::CbCascadedChild, :around_create_open],

        [InterceptableSpec::CbCascadedChild, :around_create_close],
        [InterceptableSpec::CbCascadedChild, :after_create],
        [InterceptableSpec::CbCascadedChild, :around_save_close],
        [InterceptableSpec::CbCascadedChild, :after_save],

        [InterceptableSpec::CbParent, :around_create_close],
        [InterceptableSpec::CbParent, :after_create],
        [InterceptableSpec::CbParent, :around_save_close],
        [InterceptableSpec::CbParent, :after_save]
      ]
    end

    it 'calls callbacks in the right order' do
      parent.save!
      expect(registry.calls).to eq expected
    end
  end

  context "with associations" do
    context "has_one" do
      let(:registry) { InterceptableSpec::CallbackRegistry.new }

      let(:parent) do
        InterceptableSpec::CbHasOneParent.new(registry).tap do |parent|
          parent.child = InterceptableSpec::CbHasOneChild.new(registry)
        end
      end

      let(:expected) do
        [
          [InterceptableSpec::CbHasOneParent, :before_validation],
          [InterceptableSpec::CbHasOneChild, :before_validation],
          [InterceptableSpec::CbHasOneChild, :after_validation],
          [InterceptableSpec::CbHasOneParent, :after_validation],
          [InterceptableSpec::CbHasOneParent, :before_save],

          [InterceptableSpec::CbHasOneParent, :around_save_open],
          [InterceptableSpec::CbHasOneParent, :before_create],
          [InterceptableSpec::CbHasOneParent, :around_create_open],

          [InterceptableSpec::CbHasOneParent, :insert_into_database],

          [InterceptableSpec::CbHasOneChild, :before_validation],
          [InterceptableSpec::CbHasOneChild, :after_validation],
          [InterceptableSpec::CbHasOneChild, :before_save],
          [InterceptableSpec::CbHasOneChild, :around_save_open],
          [InterceptableSpec::CbHasOneChild, :before_create],
          [InterceptableSpec::CbHasOneChild, :around_create_open],

          [InterceptableSpec::CbHasOneChild, :around_create_close],
          [InterceptableSpec::CbHasOneChild, :after_create],
          [InterceptableSpec::CbHasOneChild, :around_save_close],
          [InterceptableSpec::CbHasOneChild, :after_save],

          [InterceptableSpec::CbHasOneParent, :around_create_close],
          [InterceptableSpec::CbHasOneParent, :after_create],
          [InterceptableSpec::CbHasOneParent, :around_save_close],
          [InterceptableSpec::CbHasOneParent, :after_save],
        ]
      end

      it 'calls callbacks in the right order' do
        parent.save!
        expect(registry.calls).to eq expected
      end
    end

    context "embeds_one" do
      let(:registry) { InterceptableSpec::CallbackRegistry.new }

      let(:parent) do
        InterceptableSpec::CbEmbedsOneParent.new(registry).tap do |parent|
          parent.child = InterceptableSpec::CbEmbedsOneChild.new(registry)
        end
      end

      context "create" do
        let(:expected) do
          [
            [InterceptableSpec::CbEmbedsOneChild, :before_validation],
            [InterceptableSpec::CbEmbedsOneChild, :after_validation],
            [InterceptableSpec::CbEmbedsOneParent, :before_validation],
            [InterceptableSpec::CbEmbedsOneChild, :before_validation],
            [InterceptableSpec::CbEmbedsOneChild, :after_validation],
            [InterceptableSpec::CbEmbedsOneParent, :after_validation],

            [InterceptableSpec::CbEmbedsOneParent, :before_save],
            [InterceptableSpec::CbEmbedsOneParent, :around_save_open],
            [InterceptableSpec::CbEmbedsOneParent, :before_create],
            [InterceptableSpec::CbEmbedsOneParent, :around_create_open],

            [InterceptableSpec::CbEmbedsOneChild, :before_save],
            [InterceptableSpec::CbEmbedsOneChild, :around_save_open],
            [InterceptableSpec::CbEmbedsOneChild, :before_create],
            [InterceptableSpec::CbEmbedsOneChild, :around_create_open],

            [InterceptableSpec::CbEmbedsOneParent, :insert_into_database],

            [InterceptableSpec::CbEmbedsOneChild, :around_create_close],
            [InterceptableSpec::CbEmbedsOneChild, :after_create],
            [InterceptableSpec::CbEmbedsOneChild, :around_save_close],
            [InterceptableSpec::CbEmbedsOneChild, :after_save],

            [InterceptableSpec::CbEmbedsOneParent, :around_create_close],
            [InterceptableSpec::CbEmbedsOneParent, :after_create],
            [InterceptableSpec::CbEmbedsOneParent, :around_save_close],
            [InterceptableSpec::CbEmbedsOneParent, :after_save]
          ]
        end

        it 'calls callbacks in the right order' do
          parent.save!
          expect(registry.calls).to eq expected
        end
      end

      context "update" do
        let(:expected) do
          [
            [InterceptableSpec::CbEmbedsOneChild, :before_validation],
            [InterceptableSpec::CbEmbedsOneChild, :after_validation],
            [InterceptableSpec::CbEmbedsOneParent, :before_validation],
            [InterceptableSpec::CbEmbedsOneChild, :before_validation],
            [InterceptableSpec::CbEmbedsOneChild, :after_validation],
            [InterceptableSpec::CbEmbedsOneParent, :after_validation],

            [InterceptableSpec::CbEmbedsOneParent, :before_save],
            [InterceptableSpec::CbEmbedsOneParent, :around_save_open],
            [InterceptableSpec::CbEmbedsOneParent, :before_update],
            [InterceptableSpec::CbEmbedsOneParent, :around_update_open],

            [InterceptableSpec::CbEmbedsOneChild, :before_save],
            [InterceptableSpec::CbEmbedsOneChild, :around_save_open],
            [InterceptableSpec::CbEmbedsOneChild, :before_update],
            [InterceptableSpec::CbEmbedsOneChild, :around_update_open],

            [InterceptableSpec::CbEmbedsOneChild, :around_update_close],
            [InterceptableSpec::CbEmbedsOneChild, :after_update],
            [InterceptableSpec::CbEmbedsOneChild, :around_save_close],
            [InterceptableSpec::CbEmbedsOneChild, :after_save],

            [InterceptableSpec::CbEmbedsOneParent, :around_update_close],
            [InterceptableSpec::CbEmbedsOneParent, :after_update],
            [InterceptableSpec::CbEmbedsOneParent, :around_save_close],
            [InterceptableSpec::CbEmbedsOneParent, :after_save]
          ]
        end

        it 'calls callbacks in the right order' do
          parent.callback_registry = nil
          parent.child.callback_registry = nil
          parent.save!

          parent.callback_registry = registry
          parent.child.callback_registry = registry
          parent.name = "name"
          parent.child.age = 10

          parent.save!
          expect(registry.calls).to eq expected
        end
      end
    end

    context "has_many" do
      let(:registry) { InterceptableSpec::CallbackRegistry.new }

      let(:parent) do
        InterceptableSpec::CbHasManyParent.new(registry).tap do |parent|
          parent.children = [
            InterceptableSpec::CbHasManyChild.new(registry),
            InterceptableSpec::CbHasManyChild.new(registry)
          ]
        end
      end

      let(:expected) do
        [
          [InterceptableSpec::CbHasManyParent, :before_validation],
          [InterceptableSpec::CbHasManyChild, :before_validation],
          [InterceptableSpec::CbHasManyChild, :after_validation],
          [InterceptableSpec::CbHasManyChild, :before_validation],
          [InterceptableSpec::CbHasManyChild, :after_validation],
          [InterceptableSpec::CbHasManyParent, :after_validation],

          [InterceptableSpec::CbHasManyParent, :before_save],
          [InterceptableSpec::CbHasManyParent, :around_save_open],
          [InterceptableSpec::CbHasManyParent, :before_create],
          [InterceptableSpec::CbHasManyParent, :around_create_open],

          [InterceptableSpec::CbHasManyParent, :insert_into_database],

          [InterceptableSpec::CbHasManyChild, :before_validation],
          [InterceptableSpec::CbHasManyChild, :after_validation],
          [InterceptableSpec::CbHasManyChild, :before_save],
          [InterceptableSpec::CbHasManyChild, :around_save_open],
          [InterceptableSpec::CbHasManyChild, :before_create],
          [InterceptableSpec::CbHasManyChild, :around_create_open],
          [InterceptableSpec::CbHasManyChild, :around_create_close],
          [InterceptableSpec::CbHasManyChild, :after_create],
          [InterceptableSpec::CbHasManyChild, :around_save_close],
          [InterceptableSpec::CbHasManyChild, :after_save],

          [InterceptableSpec::CbHasManyChild, :before_validation],
          [InterceptableSpec::CbHasManyChild, :after_validation],
          [InterceptableSpec::CbHasManyChild, :before_save],
          [InterceptableSpec::CbHasManyChild, :around_save_open],
          [InterceptableSpec::CbHasManyChild, :before_create],
          [InterceptableSpec::CbHasManyChild, :around_create_open],
          [InterceptableSpec::CbHasManyChild, :around_create_close],
          [InterceptableSpec::CbHasManyChild, :after_create],
          [InterceptableSpec::CbHasManyChild, :around_save_close],
          [InterceptableSpec::CbHasManyChild, :after_save],

          [InterceptableSpec::CbHasManyParent, :around_create_close],
          [InterceptableSpec::CbHasManyParent, :after_create],
          [InterceptableSpec::CbHasManyParent, :around_save_close],
          [InterceptableSpec::CbHasManyParent, :after_save]
        ]
      end

      it 'calls callbacks in the right order' do
        parent.save!
        expect(registry.calls).to eq expected
      end
    end

    context "embeds_many" do
      let(:registry) { InterceptableSpec::CallbackRegistry.new }

      let(:parent) do
        InterceptableSpec::CbEmbedsManyParent.new(registry).tap do |parent|
          parent.children = [
            InterceptableSpec::CbEmbedsManyChild.new(registry),
            InterceptableSpec::CbEmbedsManyChild.new(registry),
          ]
        end
      end

      let(:expected) do
        [
          [InterceptableSpec::CbEmbedsManyChild, :before_validation],
          [InterceptableSpec::CbEmbedsManyChild, :after_validation],
          [InterceptableSpec::CbEmbedsManyChild, :before_validation],
          [InterceptableSpec::CbEmbedsManyChild, :after_validation],
          [InterceptableSpec::CbEmbedsManyParent, :before_validation],
          [InterceptableSpec::CbEmbedsManyChild, :before_validation],
          [InterceptableSpec::CbEmbedsManyChild, :after_validation],
          [InterceptableSpec::CbEmbedsManyChild, :before_validation],
          [InterceptableSpec::CbEmbedsManyChild, :after_validation],
          [InterceptableSpec::CbEmbedsManyParent, :after_validation],

          [InterceptableSpec::CbEmbedsManyParent, :before_save],
          [InterceptableSpec::CbEmbedsManyParent, :around_save_open],
          [InterceptableSpec::CbEmbedsManyParent, :before_create],
          [InterceptableSpec::CbEmbedsManyParent, :around_create_open],

          [InterceptableSpec::CbEmbedsManyChild, :before_save],
          [InterceptableSpec::CbEmbedsManyChild, :around_save_open],
          [InterceptableSpec::CbEmbedsManyChild, :before_save],

          [InterceptableSpec::CbEmbedsManyChild, :around_save_open],
          [InterceptableSpec::CbEmbedsManyChild, :before_create],
          [InterceptableSpec::CbEmbedsManyChild, :around_create_open],

          [InterceptableSpec::CbEmbedsManyChild, :before_create],
          [InterceptableSpec::CbEmbedsManyChild, :around_create_open],

          [InterceptableSpec::CbEmbedsManyParent, :insert_into_database],

          [InterceptableSpec::CbEmbedsManyChild, :around_create_close],
          [InterceptableSpec::CbEmbedsManyChild, :after_create],

          [InterceptableSpec::CbEmbedsManyChild, :around_create_close],
          [InterceptableSpec::CbEmbedsManyChild, :after_create],

          [InterceptableSpec::CbEmbedsManyChild, :around_save_close],
          [InterceptableSpec::CbEmbedsManyChild, :after_save],

          [InterceptableSpec::CbEmbedsManyChild, :around_save_close],
          [InterceptableSpec::CbEmbedsManyChild, :after_save],

          [InterceptableSpec::CbEmbedsManyParent, :around_create_close],
          [InterceptableSpec::CbEmbedsManyParent, :after_create],
          [InterceptableSpec::CbEmbedsManyParent, :around_save_close],
          [InterceptableSpec::CbEmbedsManyParent, :after_save]
        ]
      end

      it 'calls callbacks in the right order' do
        parent.save!
        expect(registry.calls).to eq expected
      end
    end
  end

  context "when accessing parent document from callbacks" do
    shared_examples 'accesses the correct parent' do
      it "accesses the correct parent in after_find" do
        expect(from_db.after_find_player).to eq(player._id)
      end

      it "accesses the correct parent in after_initialize" do
        expect(from_db.after_initialize_player).to eq(player._id)
      end

      it "accesses the correct parent in default" do
        expect(from_db.after_default_player).to eq(player._id)
      end

      it "accesses the correct parent in unpersisted after_initialize" do
        expect(unpersisted.after_initialize_player).to eq(player._id)
      end
    end

    context "when using create methods" do

      context "when the child is an embeds_many association" do
        let!(:player) do
          Player.create!.tap do |player|
            player.implants.create!
          end
        end

        let(:unpersisted) { player.implants.first }

        before do
          # The default is originally set when creating this document, and it is
          # subsequently persisted to the database. Therefore when we retrieve
          # this document from the database, this field is already set, and
          # the default Proc is not called. This unset is needed to allow the
          # default Proc to be called when the document is retrieved from the
          # database.
          Player.find(player.id).implants.first.unset(:after_default_player)
        end

        let(:from_db) do
          Player.find(player.id).implants.first
        end

        include_examples 'accesses the correct parent'
      end

      context "when the child is an embeds_one association" do
        let!(:player) do
          Player.create!.tap do |player|
            player.create_augmentation
          end
        end

        let(:unpersisted) { player.augmentation }

        before do
          Player.find(player.id).augmentation.unset(:after_default_player)
        end

        let(:from_db) do
          Player.find(player.id).augmentation
        end

        include_examples 'accesses the correct parent'
      end

      context "when the child is a has_many association" do
        let!(:player) do
          Player.create!.tap do |player|
            player.weapons.create!
          end
        end

        let(:unpersisted) { player.weapons.first }

        before do
          Player.find(player.id).weapons.first.unset(:after_default_player)
        end

        let(:from_db) do
          Player.find(player.id).weapons.first
        end

        include_examples 'accesses the correct parent'
      end

      context "when the child is a has_one association" do
        let!(:player) do
          Player.create!.tap do |player|
            player.create_powerup
            player.save!
          end
        end

        let(:unpersisted) { player.powerup }

        before do
          Player.find(player.id).powerup.unset(:after_default_player)
        end

        let(:from_db) do
          Player.find(player.id).powerup
        end

        include_examples 'accesses the correct parent'
      end

      context "when the child is a has_and_belongs_to_many association" do
        let!(:player) do
          Player.create!.tap do |player|
            player.shields.create!
          end
        end

        let(:unpersisted) { player.shields.first }

        before do
          Player.find(player.id).shields.unset(:after_default_player)
        end

        let(:from_db) do
          Player.find(player.id).shields.first
        end

        include_examples 'accesses the correct parent'
      end
    end

    context "when using build methods" do

      context "when the child is an embeds_many association" do
        let!(:player) do
          Player.create!.tap do |player|
            player.implants.build
            player.implants.first.save!
          end
        end

        let(:unpersisted) { player.implants.first }

        before do
          Player.find(player.id).implants.first.unset(:after_default_player)
        end

        let(:from_db) do
          Player.find(player.id).implants.first
        end

        include_examples 'accesses the correct parent'
      end

      context "when the child is an embeds_one association" do
        let!(:player) do
          Player.create!.tap do |player|
            player.build_augmentation
            player.save!
          end
        end

        let(:unpersisted) { player.augmentation }

        before do
          Player.find(player.id).augmentation.unset(:after_default_player)
        end

        let(:from_db) do
          Player.find(player.id).augmentation
        end

        include_examples 'accesses the correct parent'
      end

      context "when the child is a has_many association" do
        let!(:player) do
          Player.create!.tap do |player|
            player.weapons.build
            player.weapons.first.save!
          end
        end

        let(:unpersisted) { player.weapons.first }

        before do
          Player.find(player.id).weapons.first.unset(:after_default_player)
        end

        let(:from_db) do
          Player.find(player.id).weapons.first
        end

        include_examples 'accesses the correct parent'
      end

      context "when the child is a has_one association" do
        let!(:player) do
          Player.create!.tap do |player|
            player.build_powerup
            player.powerup.save!
          end
        end

        let(:unpersisted) { player.powerup }

        before do
          Player.find(player.id).powerup.unset(:after_default_player)
        end

        let(:from_db) do
          Player.find(player.id).powerup
        end

        include_examples 'accesses the correct parent'
      end

      context "when the child is a has_and_belongs_to_many association" do
        let!(:player) do
          Player.create!.tap do |player|
            player.shields.build
            player.shields.first.save!
          end
        end

        let(:unpersisted) { player.shields.first }

        before do
          Player.find(player.id).shields.unset(:after_default_player)
        end

        let(:from_db) do
          Player.find(player.id).shields.first
        end

        include_examples 'accesses the correct parent'
      end
    end
  end

  context "when accessing associations in defaults" do
    context "when not using autobuilding" do
      let(:band) { InterceptableBand.create(name: "Molejo") }
      let(:song) { band.songs.create(name: "Cilada") }

      it "assigns the default correctly" do
        expect(song.band_name).to eq("Molejo")
      end
    end

    context "when using autobuilding" do
      before do
        InterceptablePlane.create!.tap do |plane|
          plane.wings.create!
        end
      end

      let(:plane) { InterceptablePlane.first }
      let(:wing) { InterceptableWing.first }
      let(:engine) { wing.engine }

      it "sets the defaults correctly" do
        expect(wing._id).to eq("hello-wing")
        expect(wing.p_id).to eq(plane._id.to_s)
        expect(wing.e_id).to eq(engine._id.to_s)
        expect(engine._id).to eq("hello-engine-#{wing.id}")
      end
    end
  end

  # This case is rather niche. The _ids method used to use the `.only` method
  # to get only the _ids for an association, which was causing a
  # MissingAttributeError to be raised when accessing another association. This
  # was fixed by using `.pluck` over `.only`. Look at MONGOID-5306 for a more
  # detailed explanation.
  context "when accessing _ids in validate and access an association in after_initialize" do
    it "doesn't raise a MissingAttributeError" do
      company = InterceptableCompany.create!
      shop = InterceptableShop.create!(company: company)
      user = InterceptableUser.new
      user.company = company
      expect do
        user.save!
      end.to_not raise_error(ActiveModel::MissingAttributeError)
    end
  end
end
