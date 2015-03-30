require "spec_helper"

describe Mongoid::Persistable::Settable do

  describe "#set" do

    context "when the document is a root document" do

      shared_examples_for "a settable root document" do

        it "sets the normal field to the new value" do
          expect(person.title).to eq("kaiser")
        end

        it "properly sets aliased fields" do
          expect(person.test).to eq("alias-test")
        end

        it "casts fields that need typecasting" do
          expect(person.dob).to eq(date)
        end

        it "returns self object" do
          expect(set).to eq(person)
        end

        it "persists the normal field set" do
          expect(person.reload.title).to eq("kaiser")
        end

        it "persists sets on aliased fields" do
          expect(person.reload.test).to eq("alias-test")
        end

        it "persists fields that need typecasting" do
          expect(person.reload.dob).to eq(date)
        end

        it "resets the dirty attributes for the sets" do
          expect(person).to_not be_changed
        end
      end

      let(:person) do
        Person.create
      end

      let(:date) do
        Date.new(1976, 11, 19)
      end

      context "when provided string fields" do

        let!(:set) do
          person.set("title" => "kaiser", "test" => "alias-test", "dob" => date)
        end

        it_behaves_like "a settable root document"
      end

      context "when provided symbol fields" do

        let!(:set) do
          person.set(title: "kaiser", test: "alias-test", dob: date)
        end

        it_behaves_like "a settable root document"
      end
    end

    context "when the document is embedded" do

      shared_examples_for "a settable embedded document" do

        it "sets the normal field to the new value" do
          expect(address.number).to eq(44)
        end

        it "properly sets aliased fields" do
          expect(address.suite).to eq("400")
        end

        it "casts fields that need typecasting" do
          expect(address.end_date).to eq(date)
        end

        it "returns self object" do
          expect(set).to eq(address)
        end

        it "persists the normal field set" do
          expect(address.reload.number).to eq(44)
        end

        it "persists the aliased field set" do
          expect(address.reload.suite).to eq("400")
        end

        it "persists the fields that need typecasting" do
          expect(address.reload.end_date).to eq(date)
        end

        it "resets the dirty attributes for the sets" do
          expect(address).to_not be_changed
        end
      end

      let(:person) do
        Person.create
      end

      let(:address) do
        person.addresses.create(street: "t")
      end

      let(:date) do
        Date.new(1976, 11, 19)
      end

      context "when provided string fields" do

        let!(:set) do
          address.set("number" => 44, "suite" => "400", "end_date" => date)
        end

        it_behaves_like "a settable embedded document"
      end

      context "when provided symbol fields" do

        let!(:set) do
          address.set(number: 44, suite: "400", end_date: date)
        end

        it_behaves_like "a settable embedded document"
      end
    end
  end

  context "when dynamic attributes are not enabled" do
    let(:account) do
      Account.create
    end

    it "raises exception for an unknown attribute " do
      expect {
        account.set(somethingnew: "somethingnew")
      }.to raise_error(Mongoid::Errors::UnknownAttribute)
    end
  end

  context "when dynamic attributes enabled" do
    let(:person) do
      Person.create
    end

    it "updates non existing attribute" do
      person.set(somethingnew: "somethingnew")
      expect(person.reload.somethingnew).to eq "somethingnew"
    end
  end

  context "with an attribute with private setter" do
    let(:agent) do
      Agent.create
    end

    let(:title) do
      "Double-Oh Seven"
    end

    it "updates the attribute" do
      agent.singleton_class.send :private, :title=
      agent.set(title: title)
      expect(agent.reload.title).to eq title
    end
  end
end
