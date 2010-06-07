require "spec_helper"

describe Mongoid::Hierarchy do

  describe "#_children" do

    let(:person) do
      Person.new(:title => "King")
    end

    context "with one level of embedding" do

      let(:name) do
        Name.new(:first_name => "Titus")
      end

      let(:address) do
        Address.new(:street => "Queen St")
      end

      before do
        person.name = name
        person.addresses << address
      end

      it "includes embeds_one documents" do
        person._children.should include(name)
      end

      it "includes embeds_many documents" do
        person._children.should include(address)
      end
    end

    context "with multiple levels of embedding" do

      let(:name) do
        Name.new(:first_name => "Titus")
      end

      let(:address) do
        Address.new(:street => "Queen St")
      end

      let(:location) do
        Location.new(:name => "Work")
      end

      before do
        person.name = name
        address.locations << location
        person.addresses << address
      end

      it "includes embeds_one documents" do
        person._children.should include(name)
      end

      it "includes embeds_many documents" do
        person._children.should include(address)
      end

      it "includes embedded documents multiple levels deep" do
        person._children.should include(location)
      end
    end
  end
end
