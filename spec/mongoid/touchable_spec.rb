# frozen_string_literal: true

require "spec_helper"
require_relative './touchable_spec_models'

describe Mongoid::Touchable do

  describe "#touch" do

    context "when the document has no timestamps" do
      let(:model) do
        TouchableSpec::NoTimestamps.create!
      end

      it "responds to #touch" do
        expect(model).to respond_to(:touch)
      end

      it "does not raise an error when called without a field" do
        model.touch
      end

      it "can touch an additional field" do
        expect(model.last_used_at).to be_nil

        model.touch(:last_used_at)
        last_used_at = model.last_used_at
        expect(last_used_at).to be_within(1).of(Time.now)
        expect(model.reload.last_used_at).to be_within(0.001).of(last_used_at)
        last_used_at = model.last_used_at

        model.touch
        expect(model.last_used_at).to eq last_used_at
        expect(model.reload.last_used_at).to eq last_used_at

        model.touch(:last_used_at)
        expect(model.last_used_at).to be > last_used_at
        expect(model.reload.last_used_at).to be > last_used_at
      end

      it "can touch an additional field using alias" do
        expect(model.last_used_at).to be_nil

        model.touch(:aliased_field)
        last_used_at = model.last_used_at
        expect(last_used_at).to be_within(1).of(Time.now)
        expect(model.reload.last_used_at).to be_within(0.001).of(last_used_at)
      end
    end

    context "when the document has no associations" do
      let(:model) do
        TouchableSpec::NoAssociations.create!
      end

      it "responds to #touch" do
        expect(model).to respond_to(:touch)
      end

      it "updates the timestamp when called" do
        model
        time_before_action = Time.now
        model.touch
        updated_at = model.updated_at
        expect(updated_at).to be > time_before_action
        expect(model.reload.updated_at).to be_within(0.001).of(updated_at)

        model.touch
        expect(model.updated_at).to be > updated_at
        expect(model.reload.updated_at).to be > updated_at
      end

      it "can touch an additional field" do
        model
        time_before_action = Time.now
        model.touch(:last_used_at)

        updated_at = model.updated_at
        expect(updated_at).to be > time_before_action
        expect(model.last_used_at).to eq updated_at
        model.reload
        expect(model.updated_at).to be_within(0.001).of(updated_at)
        expect(model.last_used_at).to eq model.updated_at
        updated_at = model.updated_at

        model.touch
        expect(model.updated_at).to be > updated_at
        expect(model.last_used_at).to eq updated_at
        model.reload
        expect(model.updated_at).to be > updated_at
        expect(model.last_used_at).to eq updated_at

        updated_at = model.updated_at
        model.touch(:last_used_at)
        expect(model.updated_at).to be > updated_at
        expect(model.last_used_at).to eq model.updated_at
        model.reload
        expect(model.updated_at).to be > updated_at
        expect(model.last_used_at).to eq model.updated_at
      end

      it "can touch an additional field" do
        model
        time_before_action = Time.now
        model.touch(:aliased_field)

        updated_at = model.updated_at
        expect(updated_at).to be > time_before_action
        expect(model.last_used_at).to eq updated_at
        model.reload
        expect(model.updated_at).to be_within(0.001).of(updated_at)
        expect(model.last_used_at).to eq model.updated_at
      end
    end

    context 'associations' do

      let(:building) do
        parent_cls.create!
      end

      let(:entrance) do
        building.entrances.create!
      end

      let(:floor) do
        building.floors.create!
      end

      context 'when embedded' do
        let(:parent_cls) { TouchableSpec::Embedded::Building }

        context 'when :touch option is true' do

          it '#touch persists synchronized updated_at on both parent and child' do
            floor
            time_before_action = Time.now
            floor.touch

            floor_updated = floor.updated_at
            expect(floor_updated).to be > time_before_action
            expect(building.updated_at).to be > time_before_action

            floor.reload
            building.reload
            expect(floor.updated_at).to be_within(0.001).of(floor_updated)
            expect(building.updated_at).to eq floor.updated_at
          end

          it '#touch with additional field persists synchronized values on both parent and child' do
            floor
            time_before_action = Time.now
            floor.touch(:last_used_at)

            floor_updated = floor.updated_at
            expect(floor_updated).to be > time_before_action
            expect(floor.last_used_at).to eq floor_updated
            expect(building.updated_at).to be > time_before_action

            floor.reload
            building.reload
            expect(floor.updated_at).to be_within(0.001).of(floor_updated)
            expect(floor.last_used_at).to eq floor.updated_at
            expect(building.updated_at).to eq floor.updated_at
          end

          it '#save! persists non-synchronized updated_at on both parent and child' do
            # TODO: Nice-to-have: #save! on embedded models should have synchronized timestamps between parent and child.
            floor
            floor.last_used_at = Time.now
            time_before_action = Time.now
            floor.save!

            # TODO: BROKEN! For some reason floor.building is nil and this causes the touch callbacks to not run on it.
            puts "This should exist: #{floor.building.inspect}"
            puts "It should be the same as this: #{floor._parent.inspect}"

            floor_updated = floor.updated_at
            building_updated = building.updated_at
            expect(floor_updated).to be > time_before_action
            expect(building_updated).to be > time_before_action

            floor.reload
            building.reload
            expect(floor.updated_at).to be_within(0.001).of(floor_updated)
            expect(building.updated_at).to be_within(0.001).of(building_updated)
          end

          it '#destroy persists updated_at on parent' do
            floor
            time_before_action = Time.now
            floor.destroy

            # TODO: BROKEN! For some reason floor.building is nil and this causes the touch callbacks to not run on it.
            puts "This should exist: #{floor.building.inspect}"
            puts "It should be the same as this: #{floor._parent.inspect}"

            building_updated = building.updated_at
            expect(building_updated).to be > time_before_action

            building.reload
            expect(building.updated_at).to be_within(0.001).of(building_updated)
          end
        end

        context 'when :touch option is not set' do

          it '#touch persists updated_at on child but not parent' do
            # TODO: BROKEN! This needs a guard method to prevent case when touch: false
            # lib/mongoid/touchable.rb line 34 `if parent` needs a guard so that it does not proceed if touch: false.

            entrance
            time_before_action = Time.now
            entrance.touch

            entrance_updated = entrance.updated_at
            building_updated = entrance.updated_at
            expect(entrance_updated).to be > time_before_action
            expect(building_updated).to be < time_before_action

            expect(entrance.reload.updated_at).to be_within(0.001).of(entrance_updated)
            expect(building.reload.updated_at).to be_within(0.001).of(building_updated)
          end

          it '#touch with additional field persists synchonized values on child but not parent' do
            # TODO: BROKEN! This needs a guard method to prevent case when touch: false
            # lib/mongoid/touchable.rb line 34 `if parent` needs a guard so that it does not proceed if touch: false.

            entrance
            time_before_action = Time.now
            entrance.touch(:last_used_at)

            entrance_updated = entrance.updated_at
            building_updated = entrance.updated_at
            expect(entrance_updated).to be > time_before_action
            expect(entrance.last_used_at).to eq entrance_updated
            expect(building_updated).to be < time_before_action

            entrance.reload
            building.reload
            expect(entrance.updated_at).to be_within(0.001).of(entrance_updated)
            expect(entrance.last_used_at).to be_within(0.001).of(entrance_updated)
            expect(building.updated_at).to be_within(0.001).of(building_updated)
          end

          it '#save! persists updated_at on child but not parent' do
            entrance
            entrance.last_used_at = Time.now
            time_before_action = Time.now
            entrance.save!

            entrance_updated = entrance.updated_at
            building_updated = building.updated_at
            expect(entrance_updated).to be > time_before_action
            expect(building_updated).to be < time_before_action

            entrance.reload
            building.reload
            expect(entrance.updated_at).to be_within(0.001).of(entrance_updated)
          end

          it '#destroy does not set updated_at on parent' do
            entrance
            time_before_action = Time.now
            entrance.destroy

            expect(entrance.updated_at).to be < time_before_action
            expect(building.updated_at).to be < time_before_action
          end
        end
      end

      context 'when referenced' do
        let(:parent_cls) { TouchableSpec::Referenced::Building }

        context 'when :touch option is true' do

          it '#touch persists non-synchronized updated_at on both parent and child' do
            floor
            time_before_action = Time.now
            floor.touch

            floor_updated = floor.updated_at
            building_updated = building.updated_at
            expect(floor_updated).to be > time_before_action
            expect(building_updated).to be > time_before_action

            floor.reload
            building.reload
            expect(floor.updated_at).to be_within(0.001).of(floor_updated)
            expect(building.updated_at).to be_within(0.001).of(building_updated)
          end

          it '#touch with additional field persists non-synchronized values on both parent and child' do
            floor
            time_before_action = Time.now
            floor.touch(:last_used_at)

            floor_updated = floor.updated_at
            building_updated = building.updated_at
            expect(floor_updated).to be > time_before_action
            expect(floor.last_used_at).to eq floor_updated
            expect(building_updated).to be > time_before_action

            floor.reload
            building.reload
            expect(floor.updated_at).to be_within(0.001).of(floor_updated)
            expect(floor.last_used_at).to eq floor.updated_at
            expect(building.updated_at).to be_within(0.001).of(building_updated)
          end

          it '#save! persists non-synchronized updated_at on both parent and child' do
            floor
            floor.last_used_at = Time.now
            time_before_action = Time.now
            floor.save!

            floor_updated = floor.updated_at
            building_updated = building.updated_at
            expect(floor_updated).to be > time_before_action
            expect(building_updated).to be > time_before_action

            floor.reload
            building.reload
            expect(floor.updated_at).to be_within(0.001).of(floor_updated)
            expect(building.updated_at).to be_within(0.001).of(building_updated)
          end

          it '#destroy persists updated_at on parent' do
            floor
            time_before_action = Time.now
            floor.destroy

            building_updated = building.updated_at
            expect(building_updated).to be > time_before_action

            building.reload
            expect(building.updated_at).to be_within(0.001).of(building_updated)
          end
        end

        context 'when :touch option is not set' do

          it '#touch sets and persists updated_at on child but not parent' do
            # TODO: BROKEN! :touch callbacks need a guard so the don't run unless association has touch: true

            entrance
            time_before_action = Time.now
            entrance.touch

            entrance_updated = entrance.updated_at
            building_updated = entrance.updated_at
            expect(entrance_updated).to be > time_before_action
            expect(building_updated).to be < time_before_action

            expect(entrance.reload.updated_at).to be_within(0.001).of(entrance_updated)
            expect(building.reload.updated_at).to be_within(0.001).of(building_updated)
          end

          it '#touch with additional field persists synchronized values on child but not parent' do
            # TODO: BROKEN! :touch callbacks need a guard so the don't run unless association has touch: true

            entrance
            time_before_action = Time.now
            entrance.touch(:last_used_at)

            entrance_updated = entrance.updated_at
            building_updated = entrance.updated_at
            expect(entrance_updated).to be > time_before_action
            expect(entrance.last_used_at).to eq entrance_updated
            expect(building_updated).to be < time_before_action

            entrance.reload
            building.reload
            expect(entrance.updated_at).to be_within(0.001).of(entrance_updated)
            expect(entrance.last_used_at).to be_within(0.001).of(entrance_updated)
            expect(building.updated_at).to be_within(0.001).of(building_updated)
          end

          it '#save! persists updated_at on child but not parent' do
            entrance
            entrance.last_used_at = Time.now
            time_before_action = Time.now
            entrance.save!

            entrance_updated = entrance.updated_at
            building_updated = building.updated_at
            expect(entrance_updated).to be > time_before_action
            expect(building_updated).to be < time_before_action

            entrance.reload
            building.reload
            expect(entrance.updated_at).to be_within(0.001).of(entrance_updated)
          end

          it '#destroy does not set updated_at on parent' do
            entrance
            time_before_action = Time.now
            entrance.destroy

            expect(entrance.updated_at).to be < time_before_action
            expect(building.updated_at).to be < time_before_action
          end
        end
      end
    end

    context "when no relations have touch options" do

      before do
        Person.send(:include, Mongoid::Touchable::InstanceMethods)
        Agent.send(:include, Mongoid::Touchable::InstanceMethods)
      end

      context "when no updated at is defined" do

        let(:person) do
          Person.create!
        end

        context "when no attribute is provided" do

          let!(:touched) do
            person.touch
          end

          it "returns true" do
            expect(touched).to be true
          end

          it "does not set the updated at field" do
            expect(person[:updated_at]).to be_nil
          end
        end

        context "when an attribute is provided" do

          let!(:touched) do
            person.touch(:lunch_time)
          end

          it "sets the attribute to the current time" do
            expect(person.lunch_time).to be_within(5).of(Time.now)
          end

          it "persists the change" do
            expect(person.reload.lunch_time).to be_within(5).of(Time.now)
          end

          it "returns true" do
            expect(touched).to be true
          end
        end

        context "when an attribute alias is provided" do

          let!(:touched) do
            person.touch(:aliased_timestamp)
          end

          it "sets the attribute to the current time" do
            expect(person.aliased_timestamp).to be_within(5).of(Time.now)
          end

          it "persists the change" do
            expect(person.reload.aliased_timestamp).to be_within(5).of(Time.now)
          end

          it "returns true" do
            expect(touched).to be true
          end
        end
      end

      context "when an updated at is defined" do

        let!(:agent) do
          Agent.create!(updated_at: 2.days.ago)
        end

        context "when no attribute is provided" do

          let!(:touched) do
            agent.touch
          end

          it "sets the updated at to the current time" do
            expect(agent.updated_at).to be_within(5).of(Time.now)
          end

          it "persists the change" do
            expect(agent.reload.updated_at).to be_within(5).of(Time.now)
          end

          it "returns true" do
            expect(touched).to be true
          end

          it "keeps changes for next callback" do
            expect(agent.changes).to_not be_empty
          end
        end

        context "when an attribute is provided" do

          let!(:touched) do
            agent.touch(:dob)
          end

          it "sets the updated at to the current time" do
            expect(agent.updated_at).to be_within(5).of(Time.now)
          end

          it "sets the attribute to the current time" do
            expect(agent.dob).to be_within(5).of(Time.now)
          end

          it "sets both attributes to the exact same time" do
            expect(agent.updated_at).to eq(agent.dob)
          end

          it "persists the updated at change" do
            expect(agent.reload.updated_at).to be_within(5).of(Time.now)
          end

          it "persists the attribute change" do
            expect(agent.reload.dob).to be_within(5).of(Time.now)
          end

          it "returns true" do
            expect(touched).to be true
          end

          it "keeps changes for next callback" do
            expect(agent.changes).to_not be_empty
          end
        end
      end

      context "when record is new" do

        let!(:agent) do
          Agent.new(updated_at: 2.days.ago)
        end

        context "when no attribute is provided" do

          let(:touched) do
            agent.touch
          end

          it "returns false" do
            expect(touched).to be false
          end
        end

        context "when an attribute is provided" do

          let(:touched) do
            agent.touch(:dob)
          end

          it "returns false" do
            expect(touched).to be false
          end
        end
      end

      context "when record is destroyed" do

        let!(:agent) do
          Agent.create!(updated_at: 2.days.ago).tap do |agent|
            agent.destroy
          end
        end

        let(:frozen_error_cls) do
          FrozenError
        end

        context "when no attribute is provided" do

          let(:touched) do
            agent.touch
          end

          it "raises FrozenError" do
            expect do
              touched
            end.to raise_error(frozen_error_cls)
          end
        end

        context "when an attribute is provided" do

          let(:touched) do
            agent.touch(:dob)
          end

          it "raises FrozenError" do
            expect do
              touched
            end.to raise_error(frozen_error_cls)
          end
        end
      end

      context "when creating the child" do

        let(:time) do
          Time.utc(2012, 4, 3, 12)
        end

        let(:jar) do
          Jar.new(_id: 1, updated_at: time).tap do |jar|
            jar.save!
          end
        end

        let!(:cookie) do
          jar.cookies.create!(updated_at: time)
        end

        it "does not touch the parent" do
          expect(jar.updated_at).to eq(time)
        end
      end
    end

    context "when relations have touch options" do

      context "when the relation is a parent of an embedded doc" do

        before do
          Page.send(:include, Mongoid::Touchable::InstanceMethods)
          Edit.send(:include, Mongoid::Touchable::InstanceMethods)
        end

        let(:page) do
          WikiPage.create!(title: "test")
        end

        let!(:edit) do
          page.edits.create!
        end

        before do
          page.unset(:updated_at)
          edit.touch
        end

        it "touches the parent document" do
          expect(page.updated_at).to be_within(5).of(Time.now)
        end
      end

      context "when the parent of embedded doc has cascade callbacks" do

        before do
          Band.send(:include, Mongoid::Touchable::InstanceMethods)
        end

        let!(:book) do
          Book.new
        end

        before do
          book.pages.new
          book.save!
          book.unset(:updated_at)
          book.pages.first.touch
        end

        it "touches the parent document" do
          expect(book.updated_at).to be_within(5).of(Time.now)
        end
      end

      context "when multiple embedded docs with cascade callbacks" do

        let!(:book) do
          Book.new
        end

        before do
          2.times { book.pages.new }
          book.save!
          book.unset(:updated_at)
          book.pages.first.content  = "foo"
          book.pages.second.content = "bar"
          book.pages.first.touch
        end

        it "touches the parent document" do
          expect(book.updated_at).to be_within(5).of(Time.now)
        end
      end

      context "when the relation is nil" do

        let!(:agent) do
          Agent.create!
        end

        context "when the relation autobuilds" do

          let!(:touched) do
            agent.touch
          end

          it "does nothing to the relation" do
            expect(agent.instance_variable_get(:@agency)).to be_nil
          end
        end
      end

      context "when the relation is not nil" do

        let!(:agent) do
          Agent.create!
        end

        let!(:agency) do
          agent.create_agency.tap do |a|
            a.unset(:updated_at)
          end
        end

        let!(:touched) do
          agent.touch
        end

        it "sets the parent updated at to the current time" do
          expect(agency.updated_at).to be_within(5).of(Time.now)
        end

        it "persists the change" do
          expect(agency.reload.updated_at).to be_within(5).of(Time.now)
        end
      end

      context "when creating the child" do

        let!(:agency) do
          Agency.create!
        end

        let!(:updated) do
          agency.updated_at
        end

        let!(:agent) do
          agency.agents.create!
        end

        it "updates the parent's updated at" do
          expect(agency.updated_at).to_not eq(updated)
        end
      end

      context "when modifying the child" do

        let!(:agency) do
          Agency.create!
        end

        let!(:agent) do
          agency.agents.create!(number: '1')
        end

        it "updates the parent's updated at" do
          expect {
            agent.update_attributes!(number: '2')
          }.to change { agency.updated_at }
        end
      end

      context "when destroying the child" do

        let!(:agency) do
          Agency.create!
        end

        let!(:agent) do
          agency.agents.create!
        end

        let!(:updated) do
          agency.updated_at
        end

        before do
          agent.destroy
        end

        it "updates the parent's updated at" do
          expect(agency.updated_at).to_not eq(updated)
        end
      end
    end

    context "when other document attributes have been changed" do

      let(:band) do
        Band.create!(name: "Placebo")
      end

      context "when an attribute is provided" do
        before do
          band.name = 'Nocebo'
          band.touch(:last_release)
        end

        it "does not persist other attribute changes" do
          expect(band.name).to eq('Nocebo')
          expect(band.reload.name).not_to eq('Nocebo')
        end
      end

      context "when an attribute is not provided" do
        before do
          band.name = 'Nocebo'
          band.touch
        end

        it "does not persist other attribute changes" do
          expect(band.name).to eq('Nocebo')
          expect(band.reload.name).not_to eq('Nocebo')
        end
      end
    end
  end
end
