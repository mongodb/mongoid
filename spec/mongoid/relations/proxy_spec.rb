require "spec_helper"

describe Mongoid::Relations::Proxy do

  describe "#extend" do

    before(:all) do
      Person.reset_callbacks(:validate)
      module Testable
      end
    end

    after(:all) do
      Object.send(:remove_const, :Testable)
    end

    let(:person) do
      Person.create
    end

    let(:name) do
      person.build_name
    end

    before do
      name.namable.extend(Testable)
    end

    it "extends the proxied object" do
      expect(person).to be_a(Testable)
    end

    context "when extending from the relation definition" do

      let!(:address) do
        person.addresses.create(street: "hobrecht")
      end

      let(:found) do
        person.addresses.find_by_street("hobrecht")
      end

      it "extends the proxy" do
        expect(found).to eq(address)
      end
    end
  end
end
