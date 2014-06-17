require "spec_helper"

describe Mongoid::Attributes::Readonly do

  describe ".attr_readonly" do

    after do
      Person.readonly_attributes.clear
    end

    context "when providing a single field" do

      before do
        Person.attr_readonly :title
      end

      it "adds the field to readonly attributes" do
        expect(Person.readonly_attributes.to_a).to eq([ "title" ])
      end
    end

    context "when providing a field alias" do

      before do
        Person.attr_readonly :aliased_timestamp
      end

      it "adds the database field name to readonly attributes" do
        expect(Person.readonly_attributes.to_a).to eq([ "at" ])
      end
    end

    context "when providing multiple fields" do

      before do
        Person.attr_readonly :title, :terms
      end

      it "adds the fields to readonly attributes" do
        expect(Person.readonly_attributes.to_a).to eq([ "title", "terms" ])
      end
    end

    context "when creating a new document with a readonly field" do

      before do
        Person.attr_readonly :title, :terms, :aliased_timestamp
      end

      let(:person) do
        Person.create(title: "sir", terms: true, aliased_timestamp: Time.at(42))
      end

      it "sets the first readonly value" do
        expect(person.title).to eq("sir")
      end

      it "sets the second readonly value" do
        expect(person.terms).to be true
      end

      it "sets the third readonly value" do
        expect(person.aliased_timestamp).to eq(Time.at(42))
      end

      it "persists the first readonly value" do
        expect(person.reload.title).to eq("sir")
      end

      it "persists the second readonly value" do
        expect(person.reload.terms).to be true
      end

      it "persists the third readonly value" do
        expect(person.reload.aliased_timestamp).to eq(Time.at(42))
      end
    end

    context "when updating an existing readonly field" do

      before do
        Person.attr_readonly :title, :terms, :score, :aliased_timestamp
      end

      let(:person) do
        Person.create(title: "sir", terms: true, score: 1, aliased_timestamp: Time.at(42))
      end

      context "when updating via the setter" do

        before do
          person.title = "mr"
          person.aliased_timestamp = Time.at(43)
          person.save
        end

        it "does not update the first field" do
          expect(person.title).to eq("sir")
        end

        it "does not update the second field" do
          expect(person.aliased_timestamp).to eq(Time.at(42))
        end

        it "does not persist the first field" do
          expect(person.reload.title).to eq("sir")
        end

        it "does not persist the second field" do
          expect(person.reload.aliased_timestamp).to eq(Time.at(42))
        end
      end

      context "when updating via inc" do

        context 'with single field operation' do
          it "raises an error " do
            expect {
              person.inc(score: 1)
            }.to raise_error(Mongoid::Errors::ReadonlyAttribute)
          end
        end

        context 'with multiple fields operation' do
          it "raises an error " do
            expect {
              person.inc(score: 1, age: 1)
            }.to raise_error(Mongoid::Errors::ReadonlyAttribute)
          end
        end
      end

      context "when updating via bit" do

        context 'with single field operation' do
          it "raises an error " do
            expect {
              person.bit(score: { or: 13 })
            }.to raise_error(Mongoid::Errors::ReadonlyAttribute)
          end
        end

        context 'with multiple fields operation' do
          it "raises an error " do
            expect {
              person.bit(
                age: { and: 13 }, score: { or: 13 }, inte: { and: 13, or: 10 }
              )
            }.to raise_error(Mongoid::Errors::ReadonlyAttribute)
          end
        end
      end

      context "when updating via []=" do

        before do
          person[:title] = "mr"
          person[:aliased_timestamp] = Time.at(43)
          person.save
        end

        it "does not update the first field" do
          expect(person.title).to eq("sir")
        end

        it "does not update the second field" do
          expect(person.aliased_timestamp).to eq(Time.at(42))
        end

        it "does not persist the first field" do
          expect(person.reload.title).to eq("sir")
        end

        it "does not persist the second field" do
          expect(person.reload.aliased_timestamp).to eq(Time.at(42))
        end
      end

      context "when updating via write_attribute" do

        before do
          person.write_attribute(:title, "mr")
          person.write_attribute(:aliased_timestamp, Time.at(43))
          person.save
        end

        it "does not update the first field" do
          expect(person.title).to eq("sir")
        end

        it "does not update the second field" do
          expect(person.aliased_timestamp).to eq(Time.at(42))
        end

        it "does not persist the first field" do
          expect(person.reload.title).to eq("sir")
        end

        it "does not persist the second field" do
          expect(person.reload.aliased_timestamp).to eq(Time.at(42))
        end
      end

      context "when updating via update_attributes" do

        before do
          person.update_attributes(title: "mr", aliased_timestamp: Time.at(43))
          person.save
        end

        it "does not update the first field" do
          expect(person.title).to eq("sir")
        end

        it "does not update the second field" do
          expect(person.aliased_timestamp).to eq(Time.at(42))
        end

        it "does not persist the first field" do
          expect(person.reload.title).to eq("sir")
        end

        it "does not persist the second field" do
          expect(person.reload.aliased_timestamp).to eq(Time.at(42))
        end
      end

      context "when updating via update_attributes!" do

        before do
          person.update_attributes!(title: "mr", aliased_timestamp: Time.at(43))
          person.save
        end

        it "does not update the first field" do
          expect(person.title).to eq("sir")
        end

        it "does not update the second field" do
          expect(person.aliased_timestamp).to eq(Time.at(42))
        end

        it "does not persist the first field" do
          expect(person.reload.title).to eq("sir")
        end

        it "does not persist the second field" do
          expect(person.reload.aliased_timestamp).to eq(Time.at(42))
        end
      end

      context "when updating via update_attribute" do

        it "raises an error" do
          expect {
            person.update_attribute(:title, "mr")
          }.to raise_error(Mongoid::Errors::ReadonlyAttribute)
        end
      end

      context "when updating via remove_attribute" do

        it "raises an error" do
          expect {
            person.remove_attribute(:title)
          }.to raise_error(Mongoid::Errors::ReadonlyAttribute)
        end
      end
    end
  end
end
