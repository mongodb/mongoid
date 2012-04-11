require "spec_helper"

describe Mongoid::Callbacks do

  class TestClass
    include Mongoid::Callbacks

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
      klass.should respond_to(:before_create)
    end

    it "includes the after_create callback" do
      klass.should respond_to(:after_create)
    end

    it "includes the before_destroy callback" do
      klass.should respond_to(:before_destroy)
    end

    it "includes the after_destroy callback" do
      klass.should respond_to(:after_destroy)
    end

    it "includes the before_save callback" do
      klass.should respond_to(:before_save)
    end

    it "includes the after_save callback" do
      klass.should respond_to(:after_save)
    end

    it "includes the before_update callback" do
      klass.should respond_to(:before_update)
    end

    it "includes the after_update callback" do
      klass.should respond_to(:after_update)
    end

    it "includes the before_validation callback" do
      klass.should respond_to(:before_validation)
    end

    it "includes the after_validation callback" do
      klass.should respond_to(:after_validation)
    end

    it "includes the after_initialize callback" do
      klass.should respond_to(:after_initialize)
    end

    it "includes the after_build callback" do
      klass.should respond_to(:after_build)
    end
  end

  describe ".after_initialize" do

    let(:game) do
      Game.new
    end

    it "runs after document instantiation" do
      game.name.should eq("Testing")
    end
  end

  describe ".after_build" do

    let(:weapon) do
      Player.new(frags: 5).weapons.build
    end

    it "runs after document build (references_many)" do
      weapon.name.should eq("Holy Hand Grenade (5)")
    end

    let(:implant) do
      Player.new(frags: 5).implants.build
    end

    it "runs after document build (embeds_many)" do
      implant.name.should eq('Cochlear Implant (5)')
    end

    let(:powerup) do
      Player.new(frags: 5).build_powerup
    end

    it "runs after document build (references_one)" do
      powerup.name.should eq("Quad Damage (5)")
    end

    let(:augmentation) do
      Player.new(frags: 5).build_augmentation
    end

    it "runs after document build (embeds_one)" do
      augmentation.name.should eq("Infolink (5)")
    end
  end

  describe ".before_create" do

    let(:artist) do
      Artist.new(name: "Depeche Mode")
    end

    context "callback returns true" do

      before do
        artist.expects(:before_create_stub).returns(true)
        artist.save
      end

      it "gets saved" do
        artist.persisted?.should be_true
      end
    end

    context "callback returns false" do

      before do
        artist.expects(:before_create_stub).returns(false)
        artist.save
      end

      it "does not get saved" do
        artist.persisted?.should be_false
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
          artist.expects(:before_save_stub).returns(true)
        end

        it "the save returns true" do
          artist.save.should be_true
        end
      end

      context "when callback returns false" do

        before do
          artist.expects(:before_save_stub).returns(false)
        end

        it "the save returns false" do
          artist.save.should be_false
        end
      end
    end

    context "when updating" do

      let(:artist) do
        Artist.create(name: "Depeche Mode").tap do |artist|
          artist.name = "The Mountain Goats"
        end
      end

      after do
        artist.delete
      end

      context "when the callback returns true" do

        before do
          artist.expects(:before_save_stub).returns(true)
        end

        it "the save returns true" do
          artist.save.should be_true
        end
      end

      context "when the callback returns false" do

        before do
          artist.expects(:before_save_stub).returns(false)
        end

        it "the save returns false" do
          artist.save.should be_false
        end
      end
    end
  end

  describe ".before_destroy" do

    let(:artist) do
      Artist.create(name: "Depeche Mode")
    end

    before do
      artist.name = "The Mountain Goats"
    end

    after do
      artist.delete
    end

    context "when the callback returns true" do

      before do
        artist.expects(:before_destroy_stub).returns(true)
      end

      it "the destroy returns true" do
        artist.destroy.should be_true
      end
    end

    context "when the callback returns false" do

      before do
        artist.expects(:before_destroy_stub).returns(false)
      end

      it "the destroy returns false" do
        artist.destroy.should be_false
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
      object.after_save_called.should be_true
    end

    it "does not run the before callbacks" do
      object.before_save_called.should be_false
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
      object.before_save_called.should be_true
    end

    it "does not run the after callbacks" do
      object.after_save_called.should be_false
    end
  end

  context "when cascading callbacks" do

    context "when the parent has a custom callback" do

      before(:all) do
        Band.define_model_callbacks(:rearrange)
      end

      after(:all) do
        Band.reset_callbacks(:rearrange)
      end

      context "when the child does not have the same callback defined" do

        let(:band) do
          Band.new
        end

        let!(:record) do
          band.records.build
        end

        it "does not cascade to the child" do
          band.run_callbacks(:rearrange).should be_true
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

          it "only executes the callbacks once for each embed" do
            note.expects(:update_saved).twice
            band.save
          end
        end
      end
    end

    context "when cascading after initialize" do

      let!(:person) do
        Person.create
      end

      before do
        person.services.create!(sid: 1)
      end

      it "doesn't cascade the initialize" do
        Service.any_instance.expects(:after_initialize_called=).never
        Person.find(person.id).should eq(person)
      end
    end

    context "when attempting to cascade on a referenced relation" do

      it "raises an error" do
        expect {
          Band.has_and_belongs_to_many :tags, cascade_callbacks: true
        }.to raise_error(Mongoid::Errors::InvalidOptions)
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
              band.save
            end

            it "executes the callback" do
              label.after_create_called.should be_true
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create(name: "Moderat")
            end

            let!(:label) do
              band.build_label(name: "Mute")
            end

            before do
              band.save
            end

            it "executes the callback" do
              label.after_create_called.should be_true
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create(name: "Moderat")
          end

          let!(:label) do
            band.create_label(name: "Mute")
          end

          before do
            label.after_create_called = false
            band.save
          end

          it "does not execute the callback" do
            label.after_create_called.should be_false
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
              band.save
            end

            it "executes the callback" do
              label.after_save_called.should be_true
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create(name: "Moderat")
            end

            let!(:label) do
              band.build_label(name: "Mute")
            end

            before do
              band.save
            end

            it "executes the callback" do
              label.after_save_called.should be_true
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create(name: "Moderat")
          end

          let!(:label) do
            band.create_label(name: "Mute")
          end

          before do
            band.save
          end

          it "executes the callback" do
            label.after_save_called.should be_true
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
              band.save
            end

            it "does not execute the callback" do
              label.after_update_called.should be_false
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create(name: "Moderat")
            end

            let!(:label) do
              band.build_label(name: "Mute")
            end

            before do
              band.save
            end

            it "does not execute the callback" do
              label.after_update_called.should be_false
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create(name: "Moderat")
          end

          context "when the child is dirty" do

            let!(:label) do
              band.create_label(name: "Mute")
            end

            before do
              label.name = "Nothing"
              band.save
            end

            it "executes the callback" do
              label.after_update_called.should be_true
            end
          end

          context "when the child is not dirty" do

            let!(:label) do
              band.build_label(name: "Mute")
            end

            before do
              band.save
            end

            it "does not execute the callback" do
              label.after_update_called.should be_false
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
              band.save
            end

            it "executes the callback" do
              label.after_validation_called.should be_true
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create(name: "Moderat")
            end

            let!(:label) do
              band.build_label(name: "Mute")
            end

            before do
              band.save
            end

            it "executes the callback" do
              label.after_validation_called.should be_true
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create(name: "Moderat")
          end

          let!(:label) do
            band.create_label(name: "Mute")
          end

          before do
            band.save
          end

          it "executes the callback" do
            label.after_validation_called.should be_true
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
              band.save
            end

            it "executes the callback" do
              record.before_create_called.should be_true
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            before do
              band.save
            end

            it "executes the callback" do
              record.before_create_called.should be_true
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create(name: "Moderat")
          end

          let!(:record) do
            band.records.create(name: "Moderat")
          end

          before do
            record.before_create_called = false
            band.save
          end

          it "does not execute the callback" do
            record.before_create_called.should be_false
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
              band.save
            end

            it "executes the callback" do
              record.before_save_called.should be_true
            end

            it "persists the change" do
              band.reload.records.first.before_save_called.should be_true
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            before do
              band.save
            end

            it "executes the callback" do
              record.before_save_called.should be_true
            end

            it "persists the change" do
              band.reload.records.first.before_save_called.should be_true
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create(name: "Moderat")
          end

          let!(:record) do
            band.records.create(name: "Moderat")
          end

          before do
            band.save
          end

          it "executes the callback" do
            record.before_save_called.should be_true
          end

          it "persists the change" do
            band.reload.records.first.before_save_called.should be_true
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
              band.save
            end

            it "does not execute the callback" do
              record.before_update_called.should be_false
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            before do
              band.save
            end

            it "does not execute the callback" do
              record.before_update_called.should be_false
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create(name: "Moderat")
          end

          let!(:record) do
            band.records.create(name: "Moderat")
          end

          context "when the child is dirty" do

            before do
              record.name = "Nothing"
              band.save
            end

            it "executes the callback" do
              record.before_update_called.should be_true
            end

            it "persists the change" do
              band.reload.records.first.before_update_called.should be_true
            end
          end

          context "when the child is not dirty" do

            before do
              band.save
            end

            it "does not execute the callback" do
              record.before_update_called.should be_false
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
              band.save
            end

            it "executes the callback" do
              record.before_validation_called.should be_true
            end

            it "persists the change" do
              band.reload.records.first.before_validation_called.should be_true
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            before do
              band.save
            end

            it "executes the callback" do
              record.before_validation_called.should be_true
            end

            it "persists the change" do
              band.reload.records.first.before_validation_called.should be_true
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create(name: "Moderat")
          end

          let!(:record) do
            band.records.create(name: "Moderat")
          end

          before do
            band.save
          end

          it "executes the callback" do
            record.before_validation_called.should be_true
          end

          it "persists the change" do
            band.reload.records.first.before_validation_called.should be_true
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
              band.save
            end

            it "executes the callback" do
              track.before_create_called.should be_true
            end
          end

          context "when the root is persisted" do

            let(:band) do
              Band.create(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            let!(:track) do
              record.tracks.build(name: "Berlin")
            end

            before do
              band.save
            end

            it "executes the callback" do
              track.before_create_called.should be_true
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create(name: "Moderat")
          end

          let!(:record) do
            band.records.create(name: "Moderat")
          end

          let!(:track) do
            record.tracks.create(name: "Berlin")
          end

          before do
            track.before_create_called = false
            band.save
          end

          it "does not execute the callback" do
            track.before_create_called.should be_false
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
              band.save
            end

            let(:reloaded) do
              band.reload.records.first
            end

            it "executes the callback" do
              track.before_save_called.should be_true
            end

            it "persists the change" do
              reloaded.tracks.first.before_save_called.should be_true
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            let!(:track) do
              record.tracks.build(name: "Berlin")
            end

            before do
              band.save
            end

            let(:reloaded) do
              band.reload.records.first
            end

            it "executes the callback" do
              track.before_save_called.should be_true
            end

            it "persists the change" do
              reloaded.tracks.first.before_save_called.should be_true
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create(name: "Moderat")
          end

          let!(:record) do
            band.records.create(name: "Moderat")
          end

          let!(:track) do
            record.tracks.create(name: "Berlin")
          end

          before do
            band.save
          end

          let(:reloaded) do
            band.reload.records.first
          end

          it "executes the callback" do
            track.before_save_called.should be_true
          end

          it "persists the change" do
            reloaded.tracks.first.before_save_called.should be_true
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
              band.save
            end

            it "does not execute the callback" do
              track.before_update_called.should be_false
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            let!(:track) do
              record.tracks.build(name: "Berlin")
            end

            before do
              band.save
            end

            it "does not execute the callback" do
              track.before_update_called.should be_false
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create(name: "Moderat")
          end

          let!(:record) do
            band.records.create(name: "Moderat")
          end

          let!(:track) do
            record.tracks.create(name: "Berlin")
          end

          context "when the child is dirty" do

            before do
              track.name = "Rusty Nails"
              band.save
            end

            let(:reloaded) do
              band.reload.records.first
            end

            it "executes the callback" do
              track.before_update_called.should be_true
            end

            it "persists the change" do
              reloaded.tracks.first.before_update_called.should be_true
            end
          end

          context "when the child is not dirty" do

            before do
              band.save
            end

            it "does not execute the callback" do
              track.before_update_called.should be_false
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

            let!(:track) do
              record.tracks.build(name: "Berlin")
            end

            before do
              band.save
            end

            it "executes the callback" do
              track.before_validation_called.should be_true
            end
          end

          context "when the parent is persisted" do

            let(:band) do
              Band.create(name: "Moderat")
            end

            let!(:record) do
              band.records.build(name: "Moderat")
            end

            let!(:track) do
              record.tracks.build(name: "Berlin")
            end

            before do
              band.save
            end

            it "executes the callback" do
              track.before_validation_called.should be_true
            end
          end
        end

        context "when the child is persisted" do

          let(:band) do
            Band.create(name: "Moderat")
          end

          let!(:record) do
            band.records.create(name: "Moderat")
          end

          let!(:track) do
            record.tracks.create(name: "Berlin")
          end

          before do
            band.save
          end

          it "executes the callback" do
            track.before_validation_called.should be_true
          end
        end
      end
    end
  end

  context "callback on valid?" do

    it "goes in all validation callback in good order" do
      shin = ValidationCallback.new
      shin.valid?
      shin.history.should eq([:before_validation, :validate, :after_validation])
    end
  end

  context "when creating child documents in callbacks" do

    let(:parent) do
      ParentDoc.new
    end

    before do
      parent.save
    end

    it "does not duplicate the child documents" do
      parent.child_docs.create(position: 1)
      ParentDoc.find(parent.id).child_docs.size.should eq(1)
    end
  end

  context "when callbacks cancel persistence" do

    let(:address) do
      Address.new(street: "123 Sesame")
    end

    before(:all) do
      Person.before_save do |doc|
        doc.mode != :prevent_save
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
        person.should be_valid
        person.save.should be_false
      end

      it "is a new record" do
        person.should be_a_new_record
        expect { person.save }.not_to change { person.new_record? }
      end

      it "is left dirty" do
        person.should be_changed
        expect { person.save }.not_to change { person.changed? }
      end

      it "child documents are left dirty" do
        address.should be_changed
        expect { person.save }.not_to change { address.changed? }
      end
    end

    context "when updating a document" do

      let(:person) do
        Person.create.tap do |person|
          person.attributes = {
            mode: :prevent_save,
            title: "Associate",
            addresses: [ address ]
          }
        end
      end

      it "#save returns false" do
        person.should be_valid
        person.save.should be_false
      end

      it "is a not a new record" do
        person.should_not be_a_new_record
        expect { person.save }.not_to change { person.new_record? }
      end

      it "is left dirty" do
        person.should be_changed
        expect { person.save }.not_to change { person.changed? }
      end

      it "child documents are left dirty" do
        address.should be_changed
        expect { person.save }.not_to change { address.changed? }
      end
    end
  end

  context "when loading a model multiple times" do

    before do
      load "spec/app/models/callback_test.rb"
      load "spec/app/models/callback_test.rb"
    end

    let(:callback) do
      CallbackTest.new
    end

    context "when saving the document" do

      it "only executes the callbacks once" do
        callback.expects(:execute).once
        callback.save
      end
    end
  end
end
