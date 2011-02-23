require "spec_helper"

describe Mongoid::Keys do

  context "when the id has changed" do

    let(:person) do
      Person.create(:ssn => "555-12-1213")
    end

    context "when the document is new" do

      let(:address) do
        person.addresses.build(:street => "Unter Dem Linden")
      end

      context "when saving" do

        before do
          address.save
        end

        let(:reloaded) do
          person.reload.addresses.find(address.id)
        end

        it "sets the new key" do
          address.id.should == "unter-dem-linden"
        end

        it "saves the new key" do
          reloaded.id.should == "unter-dem-linden"
        end
      end
    end

    context "when the document is not new" do

      let(:address) do
        person.addresses.create(:street => "Unter Dem Linden")
      end

      before do
        address.street = "Wienerstrasse"
      end

      context "when after a save" do

        before do
          address.save
        end

        let(:reloaded) do
          person.reload.addresses.find(address.id)
        end

        it "sets the new key" do
          address.id.should == "wienerstrasse"
        end

        it "saves the new key" do
          reloaded.id.should == "wienerstrasse"
        end
      end
    end
  end
end
