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
        address_two._parent.should eq(person)
      end

      it "sets the inverse relation" do
        address_two.addressable.should eq(person)
      end
    end

    context "when the document is not bindable" do

      it "does nothing" do
        person.addresses.should_receive(:<<).never
        binding.bind_one(address)
      end
    end
  end
end
