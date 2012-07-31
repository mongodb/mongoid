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
        binding.bind_one
      end

      it "parentizes the documents" do
        target._parent.should eq(person)
      end

      it "sets the inverse relation" do
        target.namable.should eq(person)
      end
    end

    context "when the document is not bindable" do

      before do
        target.namable = person
      end

      it "does nothing" do
        person.should_receive(:name=).never
        binding.bind_one
      end
    end
  end

  describe "#unbind" do

    let(:binding) do
      described_class.new(person, target, metadata)
    end

    context "when the document is unbindable" do

      before do
        binding.bind_one
        binding.unbind_one
      end

      it "removes the inverse relation" do
        target.namable.should be_nil
      end
    end

    context "when the document is not unbindable" do

      it "does nothing" do
        person.should_receive(:name=).never
        binding.unbind_one
      end
    end
  end
end
