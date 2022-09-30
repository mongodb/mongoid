# frozen_string_literal: true

require "spec_helper"
require_relative './touchable_spec_models'

describe Mongoid::Touchable do

  describe "#touch" do

    context "when the document has no associations" do
      let(:updatable) do
        Updatable.create!
      end

      it "responds to #touch" do
        expect(updatable).to respond_to(:touch)
      end

      it "updates the timestamp when called" do
        expect(updatable.updated_at).to be_nil

        updatable.touch
        updated_at = updatable.updated_at
        expect(updated_at).not_to be_nil

        updatable.touch
        expect(updatable.updated_at).to be > updated_at
      end
    end

    context 'when the document has a parent association' do

      let(:building) do
        parent_cls.create!
      end

      let(:entrance) do
        building.entrances.create!
      end

      let(:floor) do
        building.floors.create!
      end

      let!(:start_time) { Timecop.freeze(Time.at(Time.now.to_i)) }

      let(:update_time) do
        Timecop.freeze(Time.at(Time.now.to_i) + 2)
      end

      after do
        Timecop.return
      end

      shared_examples 'updates the child' do
        it "updates the updated_at timestamp" do
          entrance
          update_time
          entrance.touch

          entrance.updated_at.should == update_time
        end

        it "persists the changes" do
          entrance
          update_time
          entrance.touch

          entrance.reload.updated_at.should == update_time
        end
      end

      shared_examples 'updates the parent when :touch is true' do

        it 'updates updated_at on parent' do
          floor
          update_time
          floor.touch

          building.updated_at.should == update_time
        end

        it 'persists updated updated_at on parent' do
          floor
          update_time
          floor.touch

          building.reload.updated_at.should == update_time
        end
      end

      shared_examples 'updates the parent when :touch is false' do
        it 'does not update updated_at on parent' do
          entrance
          update_time
          entrance.touch

          building.updated_at.should == update_time
        end

        it 'does not persist updated updated_at on parent' do
          entrance
          update_time
          entrance.touch

          building.reload.updated_at.should == update_time
        end
      end

      shared_examples 'does not update the parent when :touch is not set' do
        it 'does not update updated_at on parent' do
          entrance
          update_time
          entrance.touch

          building.updated_at.should == start_time
        end

        it 'does not persist updated updated_at on parent' do
          entrance
          update_time
          entrance.touch

          building.reload.updated_at.should == start_time
        end
      end

      context "when the document is embedded" do
        let(:parent_cls) { TouchableSpec::Embedded::Building }

        include_examples 'updates the child'
        include_examples 'updates the parent when :touch is true'
        include_examples 'updates the parent when :touch is false'

        context 'when also updating an additional field' do
          it 'persists the update to the additional field' do
            entrance
            update_time
            entrance.touch(:last_used_at)

            entrance.reload
            building.reload

            # This is the assertion we want.
            entrance.last_used_at.should == update_time

            # Check other timestamps for good measure.
            entrance.updated_at.should == update_time
            building.updated_at.should == update_time
          end
        end
      end

      context "when the document is referenced" do
        let(:parent_cls) { TouchableSpec::Referenced::Building }

        include_examples 'updates the child'
        include_examples 'updates the parent when :touch is true'
        include_examples 'does not update the parent when :touch is not set'
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

    context "when the touch option is true" do

      shared_examples "updates the parent's updated_at" do

        let!(:start_time) { Timecop.freeze(Time.at(Time.now.to_i)) }

        let(:update_time) do
          Timecop.freeze(Time.at(Time.now.to_i) + 2)
        end

        after do
          Timecop.return
        end

        let(:building) do
          parent_cls.create!
        end

        let(:floor) do
          building.floors.create!
        end

        before do
          floor
          update_time
          floor.level = 9
          floor.send(meth)
        end

        it "the parent is not nil" do
          expect(floor.building).to_not be nil
        end

        it "updates the parent's timestamp" do
          building.updated_at.should == update_time
          building.reload.updated_at.should == update_time
        end
      end

      shared_examples "updates the child's updated_at" do

        let!(:start_time) { Timecop.freeze(Time.at(Time.now.to_i)) }

        let(:update_time) do
          Timecop.freeze(Time.at(Time.now.to_i) + 2)
        end

        after do
          Timecop.return
        end

        let(:building) do
          parent_cls.create!
        end

        let(:floor) do
          building.floors.create!
        end

        before do
          floor
          update_time
          floor.level = 9
          floor.send(meth)
        end

        it "the parent is not nil" do
          expect(floor.building).to_not be nil
        end

        it "updates the child's timestamp" do
          floor.updated_at.should == update_time
          floor.reload.updated_at.should == update_time
        end
      end

      [ :save!, :destroy, :touch].each do |meth|
        context "with #{meth} on referenced associations" do
          let(:parent_cls) { TouchableSpec::Referenced::Building }
          let(:meth) { meth }

          include_examples "updates the child's updated_at" unless meth == :destroy
          include_examples "updates the parent's updated_at"
        end

        context "with #{meth} on embedded associations" do
          let(:parent_cls) { TouchableSpec::Embedded::Building }
          let(:meth) { meth }

          include_examples "updates the child's updated_at" unless meth == :destroy
          include_examples "updates the parent's updated_at"
        end
      end
    end

    context "when the touch option is false" do

      shared_examples "does not update the parent" do

        let!(:start_time) { Timecop.freeze(Time.at(Time.now.to_i)) }

        let(:update_time) do
          Timecop.freeze(Time.at(Time.now.to_i) + 2)
        end

        after do
          Timecop.return
        end

        let(:building) do
          parent_cls.create!
        end

        let(:entrance) do
          building.entrances.create!
        end

        before do
          entrance
          update_time
          entrance.touch
        end

        it "updates the child's timestamp" do
          entrance.updated_at.should == update_time
          entrance.reload.updated_at.should == update_time
        end

        it "does not update the parent's timestamp" do
          building.updated_at.should == start_time
          building.reload.updated_at.should == start_time
        end
      end

      [ :save!, :destroy, :touch].each do |meth|
        context "with #{meth} on belongs_to" do
          let(:meth) { meth }
          let(:parent_cls) { TouchableSpec::Referenced::Building }

          include_examples "does not update the parent"
        end

        context "with #{meth} on embedded_in" do
          let(:meth) { meth }
          let(:parent_cls) { TouchableSpec::Embedded::Building }

          before do
            skip "MONGOID-5274"
          end

          include_examples "does not update the parent"
        end
      end
    end
  end

  describe "when saving a document" do

    let!(:start_time) { Timecop.freeze(Time.at(Time.now.to_i)) }

    let(:update_time) do
      Timecop.freeze(Time.at(Time.now.to_i) + 2)
    end

    after do
      Timecop.return
    end

    context "when only using the root document" do

      shared_examples "timeless is cleared" do
        it "clears the timeless option" do
          expect(doc.timeless?).to be false
        end
      end

      shared_examples "touches the document" do
        it "touches the document" do
          expect(doc.created_at).to eq(start_time)
          expect(doc.updated_at).to eq(start_time)
        end
      end

      shared_examples "updates the document" do
        it "updates the document" do
          expect(doc.created_at).to eq(start_time)
          expect(doc.updated_at).to eq(update_time)
        end
      end

      let(:doc) { Dokument.new }

      context "when saving a new document" do

        context "when not passing a touch option" do

          before do
            doc.save!
          end

          include_examples "touches the document"
          include_examples "timeless is cleared"
        end

        context "when passing touch: true" do

          before do
            doc.save!(touch: true)
          end

          include_examples "touches the document"
          include_examples "timeless is cleared"
        end

        context "when passing touch: false" do

          before do
            doc.save!(touch: false)
          end

          include_examples "touches the document"
          include_examples "timeless is cleared"
        end
      end

      context "when updating a document" do
        before do
          doc.save!
          doc.title = "title"
          update_time
        end

        context "when not passing a touch option" do

          before do
            doc.save!
          end

          include_examples "updates the document"
          include_examples "timeless is cleared"
        end

        context "when passing touch: true" do

          before do
            doc.save!(touch: true)
          end

          include_examples "updates the document"
          include_examples "timeless is cleared"
        end

        context "when passing touch: false" do

          before do
            doc.save!(touch: false)
          end

          include_examples "touches the document"
          include_examples "timeless is cleared"
        end
      end
    end

    context "when saving embedded associations with cascadable callbacks" do

      shared_examples "timeless is cleared" do
        it "clears the timeless option" do
          expect(book.timeless?).to be false
          expect(book.covers.first.timeless?).to be false
        end
      end

      shared_examples "touches the document" do
        it "touches the document" do
          expect(book.created_at).to eq(start_time)
          expect(book.updated_at).to eq(start_time)
        end
      end

      shared_examples "updates the document" do
        it "updates the document" do
          expect(book.created_at).to eq(start_time)
          expect(book.updated_at).to eq(update_time)
        end
      end

      shared_examples "touches the children" do
        it "touches the children" do
          expect(book.covers.first.created_at).to eq(start_time)
          expect(book.covers.first.updated_at).to eq(start_time)
        end
      end

      shared_examples "updates the children" do
        it "updates the children" do
          expect(book.covers.first.created_at).to eq(start_time)
          expect(book.covers.first.updated_at).to eq(update_time)
        end
      end

      let(:book) do
        Book.new(covers: [ cover ])
      end

      let(:cover) do
        Cover.new
      end

      context "when saving a new document" do

        context "when not passing a touch option" do

          before do
            book.save!
          end

          include_examples "touches the document"
          include_examples "touches the children"
          include_examples "timeless is cleared"
        end

        context "when passing touch: true" do

          before do
            book.save!(touch: true)
          end

          include_examples "touches the document"
          include_examples "touches the children"
          include_examples "timeless is cleared"
        end

        context "when passing touch: false" do

          before do
            book.save!(touch: false)
          end

          include_examples "touches the document"
          include_examples "touches the children"
          include_examples "timeless is cleared"
        end
      end

      context "when updating a document" do
        before do
          book.save!
          book.title = "title"
          book.covers.first.title = "title"
          update_time
        end

        context "when not passing a touch option" do

          before do
            book.save!
          end

          include_examples "updates the document"
          include_examples "updates the children"
          include_examples "timeless is cleared"
        end

        context "when passing touch: true" do

          before do
            book.save!(touch: true)
          end

          include_examples "updates the document"
          include_examples "updates the children"
          include_examples "timeless is cleared"
        end

        context "when passing touch: false" do

          before do
            book.save!(touch: false)
          end

          include_examples "touches the document"
          include_examples "touches the children"
          include_examples "timeless is cleared"
        end
      end
    end
  end
end
