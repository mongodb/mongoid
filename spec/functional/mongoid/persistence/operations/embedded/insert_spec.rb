require "spec_helper"

describe Mongoid::Persistence::Operations::Embedded::Insert do

  before do
    Person.delete_all
    Mongoid::IdentityMap.clear
  end

  describe "#persist" do

    context "when the insert succeeded" do

      let(:person) do
        Person.create(:ssn => "323-21-1111")
      end

      let(:address) do
        person.addresses.create(:street => "Hobrechtstr")
      end

      let(:in_map) do
        Mongoid::IdentityMap.get(address.id)
      end

      it "does not put the document in the identity map" do
        in_map.should be_nil
      end
    end
  end
end
