require "spec_helper"

describe Mongoid::Relations::Bindings::Embedded::Many do

  let(:person) do
    Person.new
  end

  let(:address) do
    Address.new
  end

  let(:target) do
    [ address ]
  end

  let(:metadata) do
    Person.relations["addresses"]
  end

  describe "#bind" do

    let(:binding) do
      described_class.new(person, target, metadata)
    end

    context "when the documents are bindable" do

      before do
        binding.bind
      end

      it "parentizes the documents" do
        address._parent.should == person
      end

      it "sets the inverse relation" do
        address.addressable.should == person
      end
    end

    context "when the documents are not bindable" do

      before do
        address.addressable = person
      end

      it "does nothing" do
        person.addresses.expects(:<<).never
        binding.bind
      end
    end
  end

  describe "#bind_one" do

    let(:binding) do
      described_class.new(person, target, metadata)
    end

    context "when the document is bindable" do

      let(:address_two) do
        Address.new
      end

      before do
        binding.bind_one(address_two)
      end

      it "parentizes the document" do
        address_two._parent.should == person
      end

      it "sets the inverse relation" do
        address_two.addressable.should == person
      end
    end

    context "when the document is not bindable" do

      it "does nothing" do
        person.addresses.expects(:<<).never
        binding.bind_one(address)
      end
    end
  end

  describe "#unbind" do

    let(:binding) do
      described_class.new(person, target, metadata)
    end

    context "when the documents are unbindable" do

      before do
        binding.bind
        binding.unbind
      end

      it "removes the inverse relation" do
        address.addressable.should be_nil
      end
    end

    context "when the documents are not unbindable" do

      it "does nothing" do
        person.expects(:addresses=).never
        binding.unbind
      end
    end
  end
end
