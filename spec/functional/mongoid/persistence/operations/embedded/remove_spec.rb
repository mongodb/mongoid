require "spec_helper"

describe Mongoid::Persistence::Operations::Remove do

  before do
    Person.delete_all
    Mongoid::IdentityMap.clear
  end

  describe "#persist" do

    context "when the remove succeeded" do

      let!(:person) do
        Person.create(:ssn => "323-21-1111")
      end

      let!(:address) do
        person.addresses.create(:street => "Wienerstr")
      end

      before do
        address.delete
      end

      let(:in_map) do
        Mongoid::IdentityMap.get(Person, address.id)
      end

      it "removes the document from the identity map" do
        in_map.should be_nil
      end
    end
  end
end
