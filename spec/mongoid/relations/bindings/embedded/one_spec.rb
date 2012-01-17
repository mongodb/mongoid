require "spec_helper"

describe Mongoid::Relations::Bindings::Embedded::One do

  let(:person) do
    Person.new
  end

  let(:target) do
    Name.new
  end

  let(:metadata) do
    Person.relations["name"]
  end

  describe "#bind" do

    let(:binding) do
      described_class.new(person, target, metadata)
    end

    context "when the document is bindable" do

      before do
        binding.bind
      end

      it "parentizes the documents" do
        target._parent.should == person
      end

      it "sets the inverse relation" do
        target.namable.should == person
      end
    end

    context "when the document is not bindable" do

      before do
        target.namable = person
      end

      it "does nothing" do
        person.expects(:name=).never
        binding.bind
      end
    end
  end

  describe "#unbind" do

    let(:binding) do
      described_class.new(person, target, metadata)
    end

    context "when the document is unbindable" do

      before do
        binding.bind
        binding.unbind
      end

      it "removes the inverse relation" do
        target.namable.should be_nil
      end
    end

    context "when the document is not unbindable" do

      it "does nothing" do
        person.expects(:name=).never
        binding.unbind
      end
    end
  end
end
