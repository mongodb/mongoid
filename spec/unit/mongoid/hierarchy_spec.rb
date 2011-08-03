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

  describe ".hereditary?" do

    context "when the document is a subclass" do

      it "returns true" do
        Circle.should be_hereditary
      end
    end

    context "when the document is not a subclass" do

      it "returns false" do
        Shape.should_not be_hereditary
      end
    end
  end

  describe "#hereditary?" do

    context "when the document is a subclass" do

      it "returns true" do
        Circle.new.should be_hereditary
      end
    end

    context "when the document is not a subclass" do

      it "returns false" do
        Shape.new.should_not be_hereditary
      end
    end
  end

  describe "#parentize" do

    let(:address) do
      Address.new
    end

    let(:person) do
      Person.new
    end

    before do
      address.parentize(person)
    end

    it "sets the parent document" do
      address._parent.should == person
    end
  end

  describe "#remove_child" do

    let(:person) do
      Person.new
    end

    context "when child is an embeds one" do

      let!(:name) do
        person.build_name(:first_name => "James")
      end

      before do
        person.remove_child(name)
      end

      it "removes the relation instance" do
        person.name.should be_nil
      end
    end

    context "when child is an embeds many" do

      let!(:address) do
        person.addresses.build(:street => "Upper St")
      end

      before do
        person.remove_child(address)
      end

      it "removes the document from the relation target" do
        person.addresses.should be_empty
      end
    end
  end

  describe "#_root" do

    let(:address) do
      Address.new
    end

    let(:person) do
      Person.new
    end

    before do
      address.parentize(person)
    end

    context "when the document is not the root" do

      it "returns the root" do
        address._root.should == person
      end
    end

    context "when the document is the root" do

      it "returns self" do
        person._root.should == person
      end
    end
  end
end
