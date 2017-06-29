require "spec_helper"

describe Mongoid::Attributes::Readonly do

  before do
    Person.attr_readonly(*attributes)
  end

  after do
    Person.readonly_attributes.reject! do |a|
      [ attributes ].flatten.include?(a.to_sym) ||
        [ attributes ].flatten.include?(Person.aliased_fields.key(a).to_sym)
    end
  end

  describe ".attr_readonly" do

    context "when providing a single field" do

      let(:attributes) do
        :title
      end

      it "adds the field to readonly attributes" do
        expect(Person.readonly_attributes.to_a).to include("title")
      end
    end

    context "when providing a field alias" do

      let(:attributes) do
        :aliased_timestamp
      end

      it "adds the database field name to readonly attributes" do
        expect(Person.readonly_attributes.to_a).to include("at")
      end
    end

    context "when providing multiple fields" do

      let(:attributes) do
        [ :title, :terms ]
      end

      it "adds the fields to readonly attributes" do
        expect(Person.readonly_attributes.to_a).to include("title", "terms")
      end
    end

    context "when creating a new document with a readonly field" do

      let(:attributes) do
        [ :title, :terms, :aliased_timestamp ]
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

      let(:attributes) do
        [ :title, :terms, :score, :aliased_timestamp ]
      end

      let(:person) do
        Person.create(title: "sir", terms: true, score: 1, aliased_timestamp: Time.at(42))
      end

      context "when updating via the setter" do

        it "does not update the first field" do
          expect {
            person.title = 'mr'
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
          expect(person.title).to eq("sir")
        end

        it "does not update the second field" do
          expect {
            person.aliased_timestamp = Time.at(43)
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
          expect(person.aliased_timestamp).to eq(Time.at(42))
        end

        it "does not persist the first field" do
          expect {
            person.title = 'mr'
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
          expect(person.reload.title).to eq("sir")
        end

        it "does not persist the second field" do
          expect {
            person.aliased_timestamp = Time.at(43)
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
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

        it "does not update the first field" do
          expect {
            person[:title] = "mr"
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
          expect(person.title).to eq("sir")
        end

        it "does not update the second field" do
          expect {
            person[:aliased_timestamp] = Time.at(43)
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
          expect(person.aliased_timestamp).to eq(Time.at(42))
        end

        it "does not persist the first field" do
          expect {
            person[:title] = "mr"
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
          expect(person.reload.title).to eq("sir")
        end

        it "does not persist the second field" do
          expect {
            person[:aliased_timestamp] = Time.at(43)
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
          expect(person.reload.aliased_timestamp).to eq(Time.at(42))
        end
      end

      context "when updating via write_attribute" do

        it "does not update the first field" do
          expect {
            person.write_attribute(:title, "mr")
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
          expect(person.title).to eq("sir")
        end

        it "does not update the second field" do
          expect {
            person.write_attribute(:aliased_timestamp, Time.at(43))
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
          expect(person.aliased_timestamp).to eq(Time.at(42))
        end

        it "does not persist the first field" do
          expect {
            person.write_attribute(:title, "mr")
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
          expect(person.reload.title).to eq("sir")
        end

        it "does not persist the second field" do
          expect {
            person.write_attribute(:aliased_timestamp, Time.at(43))
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
          expect(person.reload.aliased_timestamp).to eq(Time.at(42))
        end
      end

      context "when updating via update_attributes" do

        it "does not update the first field" do
          expect {
            person.update_attributes(title: "mr", aliased_timestamp: Time.at(43))
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
          expect(person.title).to eq("sir")
        end

        it "does not update the second field" do
          expect {
            person.update_attributes(title: "mr", aliased_timestamp: Time.at(43))
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
          expect(person.aliased_timestamp).to eq(Time.at(42))
        end

        it "does not persist the first field" do
          expect {
            person.update_attributes(title: "mr", aliased_timestamp: Time.at(43))
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
          expect(person.reload.title).to eq("sir")
        end

        it "does not persist the second field" do
          expect {
            person.update_attributes(title: "mr", aliased_timestamp: Time.at(43))
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
          expect(person.reload.aliased_timestamp).to eq(Time.at(42))
        end
      end

      context "when updating via update_attributes!" do

        it "does not update the first field" do
          expect {
            person.update_attributes!(title: "mr", aliased_timestamp: Time.at(43))
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
          expect(person.title).to eq("sir")
        end

        it "does not update the second field" do
          expect {
            person.update_attributes!(title: "mr", aliased_timestamp: Time.at(43))
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
          expect(person.aliased_timestamp).to eq(Time.at(42))
        end

        it "does not persist the first field" do
          expect {
            person.update_attributes!(title: "mr", aliased_timestamp: Time.at(43))
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
          expect(person.reload.title).to eq("sir")
        end

        it "does not persist the second field" do
          expect {
            person.update_attributes!(title: "mr", aliased_timestamp: Time.at(43))
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
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

      context "belongs_to field is readonly" do
        it do
          mother = Person.create
          Person.create(mother: mother)
          child = Person.find_by(mother: mother)
          expect {
            child.mother
          }.not_to raise_error
        end
      end
    end
  end
end
