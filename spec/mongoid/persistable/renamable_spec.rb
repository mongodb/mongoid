# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Persistable::Renamable do

  describe "#rename" do

    context "when the document is a root document" do

      shared_examples_for "a renamable root document" do

        it "renames the first field" do
          expect(person.salutation).to eq("sir")
        end

        it "removes the first original value" do
          expect(person.title).to be_nil
        end

        it "renames the second field" do
          expect(person.date_of_birth.to_date).to eq(date)
        end

        it "removes the second original value" do
          expect(person.dob).to be_nil
        end

        it "returns self object" do
          expect(rename).to eq(person)
        end

        it "persists the first rename" do
          expect(person.reload.salutation).to eq("sir")
        end

        it "persists the first original removal" do
          expect(person.reload.title).to be_nil
        end

        it "persists the second rename" do
          expect(person.reload.date_of_birth.to_date).to eq(date)
        end

        it "persists the second original removal" do
          expect(person.reload.dob).to be_nil
        end

        it "clears out the dirty changes" do
          expect(person).to_not be_changed
        end
      end

      let(:date) do
        Date.new(2013, 1, 1)
      end

      let(:person) do
        Person.create!(title: "sir", dob: date)
      end

      context "when provided symbol names" do

        let!(:rename) do
          person.rename(title: :salutation, dob: :date_of_birth)
        end

        it_behaves_like "a renamable root document"
      end

      context "when provided string names" do

        let!(:rename) do
          person.rename(title: "salutation", dob: "date_of_birth")
        end

        it_behaves_like "a renamable root document"
      end
    end

    context "when the document is embedded" do

      shared_examples_for "a renamable embedded document" do

        it "renames the first field" do
          expect(name.mi).to eq("blah")
        end

        it "removes the first original value" do
          expect(name.middle).to be_nil
        end

        it "returns self object" do
          expect(rename).to eq(name)
        end

        it "persists the first rename" do
          expect(name.reload.mi).to eq("blah")
        end

        it "persists the first original removal" do
          expect(name.reload.middle).to be_nil
        end

        it "clears out the dirty changes" do
          expect(name).to_not be_changed
        end
      end

      let(:person) do
        Person.create!
      end

      let(:name) do
        person.create_name(first_name: "test", last_name: "user", middle: "blah")
      end

      context "when provided symbol names" do

        let!(:rename) do
          name.rename(middle: :mi)
        end

        it_behaves_like "a renamable embedded document"
      end

      context "when provided string names" do

        let!(:rename) do
          name.rename(middle: "mi")
        end

        it_behaves_like "a renamable embedded document"
      end
    end

    context "when executing atomically" do

      let(:person) do
        Person.create!(title: "sir")
      end

      it "marks a dirty change for the renamed fields" do
        person.atomically do
          person.rename title: :salutation
          expect(person.changes).to eq({"title" => ["sir", nil], "salutation" => [nil, "sir"]})
        end
      end
    end

    context "when executing on a readonly document" do

      let(:person) do
        Person.create!(title: "sir")
      end

      context "when legacy_readonly is true" do
        config_override :legacy_readonly, true

        before do
          person.__selected_fields = { "test_array" => 1 }
        end

        it "persists the changes" do
          expect(person).to be_readonly
          person.rename title: :salutation
          expect(person.reload.salutation).to eq("sir")
        end
      end

      context "when legacy_readonly is false" do
        config_override :legacy_readonly, false

        before do
          person.readonly!
        end

        it "raises a ReadonlyDocument error" do
          expect(person).to be_readonly
          expect do
            person.rename(title: :salutation)
          end.to raise_error(Mongoid::Errors::ReadonlyDocument)
        end
      end
    end
  end
end
