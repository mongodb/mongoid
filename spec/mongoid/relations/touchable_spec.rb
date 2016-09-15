require "spec_helper"

describe Mongoid::Relations::Touchable do

  describe "#touch" do

    context "when the document is embedded" do

      let(:band) do
        Band.create(name: "Placebo")
      end

      let(:label) do
        band.create_label(name: "Mute", updated_at: 10.days.ago)
      end

      before do
        label.touch
      end

      it "updates the updated_at timestamp" do
        expect(label.updated_at).to be_within(1).of(Time.now)
      end

      it "persists the changes" do
        expect(label.reload.updated_at).to be_within(1).of(Time.now)
      end
    end

    context "when no relations have touch options" do

      context "when no updated at is defined" do

        let(:person) do
          Person.create
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
          Agent.create(updated_at: 2.days.ago)
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

        let(:agent) do
          Agent.new(updated_at: 2.days.ago)
        end

        context "when no attribute is provided" do

          let!(:touched) do
            agent.touch
          end

          it "returns false" do
            expect(touched).to be false
          end
        end

        context "when an attribute is provided" do

          let!(:touched) do
            agent.touch(:dob)
          end

          it "returns false" do
            expect(touched).to be false
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

        let(:page) do
          WikiPage.create(title: "test")
        end

        let!(:edit) do
          page.edits.create
        end

        before do
          page.unset(:updated_at)
          edit.touch
        end

        it "touches the parent document" do
          expect(page.updated_at).to be_within(5).of(Time.now)
        end
      end

      context "when the relation is nil" do

        let!(:agent) do
          Agent.create
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
          Agent.create
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
          Agency.create
        end

        let!(:updated) do
          agency.updated_at
        end

        let!(:agent) do
          agency.agents.create
        end

        it "updates the parent's updated at" do
          expect(agency.updated_at).to_not eq(updated)
        end
      end

      context "when modifying the child" do

        let!(:agency) do
          Agency.create
        end

        let!(:agent) do
          agency.agents.create(number: '1')
        end

        it "updates the parent's updated at" do
          expect {
            agent.update_attributes(number: '2')
          }.to change { agency.updated_at }
        end
      end

      context "when destroying the child" do

        let!(:agency) do
          Agency.create
        end

        let!(:agent) do
          agency.agents.create
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
        Band.create(name: "Placebo")
      end

      context "when an attribute is provided" do
        before do
          band.name = 'Nocebo'
          band.touch(:last_release)
        end

        it "does not persist other attribute changes" do
          expect(band.reload.name).not_to eq('Nocebo')
        end
      end

      context "when an attribute is not provided" do
        before do
          band.name = 'Nocebo'
          band.touch
        end

        it "does not persist other attribute changes" do
          expect(band.reload.name).not_to eq('Nocebo')
        end
      end
    end
  end
end
