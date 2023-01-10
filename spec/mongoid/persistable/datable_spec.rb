# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Persistable::Datable do

  describe "#current_date" do

    context "when the document is a root document" do
      let(:band) { Band.create! }

      shared_examples_for "a datable root document" do

        it 'sets the fields to the current date/time' do
          expect(band.reload.created).to be > 1.second.ago
          expect(band.founded).to be == Date.today
        end

        it "resets dirty changes" do
          expect(band).to_not be_changed
        end
      end

      context 'when given only field names' do
        before { band.current_date(:created, "founded") }
        it_behaves_like "a datable root document"
      end

      context 'when given only `true` with field names' do
        before { band.current_date(created: true, "founded" => true) }
        it_behaves_like "a datable root document"
      end

      context 'when given explicit type arguments' do
        before { band.current_date(created: :timestamp, founded: :date) }
        it_behaves_like "a datable root document"
      end

      context 'when mixing different argument types' do
        before { band.current_date(:created, founded: :date) }
        it_behaves_like "a datable root document"
      end
    end

    context "when the document is an embedded document" do
      let(:person) { Person.create! }
      let(:address) { person.addresses.create!(street: "t", number: 60, no: 60, house: 60) }

      shared_examples_for "a datable embedded document" do

        it 'sets the fields to the current date/time' do
          expect(address.reload.move_in).to be > 1.second.ago
          expect(address.end_date).to be == Date.today
        end

        it "resets dirty changes" do
          expect(address).to_not be_changed
        end
      end

      context 'when given only field names' do
        before { address.current_date(:move_in, "end_date") }
        it_behaves_like "a datable embedded document"
      end

      context 'when given only `true` with field names' do
        before { address.current_date(move_in: true, "end_date" => true) }
        it_behaves_like "a datable embedded document"
      end

      context 'when given explicit type arguments' do
        before { address.current_date(move_in: :timestamp, end_date: :date) }
        it_behaves_like "a datable embedded document"
      end

      context 'when mixing different argument types' do
        before { address.current_date(:move_in, end_date: :date) }
        it_behaves_like "a datable embedded document"
      end
    end

    context "when executing atomically" do

      let(:stamp) { 7.days.ago }
      let(:band) { Band.create! created: stamp, founded: stamp }

      it "marks a dirty change for the modified fields" do
        band.atomically do
          band.current_date :created, :founded
          expect(band.changes.keys)
            .to include("created", "founded")
        end
      end
    end

    context "when executing on a readonly document" do
      let(:band) { Band.create! }

      context "when legacy_readonly is true" do
        config_override :legacy_readonly, true

        before do
          band.__selected_fields = { "created" => 1, "founded" => 1 }
        end

        it "persists the changes" do
          expect(band).to be_readonly
          band.current_date(:created, :founded)
          expect(band.reload.created).to be > 1.second.ago
          expect(band.founded).to be == Date.today
        end
      end

      context "when legacy_readonly is false" do
        config_override :legacy_readonly, false

        before do
          band.readonly!
        end

        it "raises a ReadonlyDocument error" do
          expect(band).to be_readonly
          expect do
            band.current_date(:created, :founded)
          end.to raise_error(Mongoid::Errors::ReadonlyDocument)
        end
      end
    end
  end
end
