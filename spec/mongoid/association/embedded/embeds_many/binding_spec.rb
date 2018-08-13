# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Association::Embedded::EmbedsMany::Binding do

  let(:person) do
    Person.new
  end

  let(:address) do
    Address.new
  end

  let(:target) do
    [ address ]
  end

  let(:association) do
    Person.relations["addresses"]
  end

  describe "#bind_one" do

    let(:binding) do
      described_class.new(person, target, association)
    end

    context "when the document is bindable" do

      let(:address_two) do
        Address.new
      end

      before do
        binding.bind_one(address_two)
      end

      it "parentizes the document" do
        expect(address_two._parent).to eq(person)
      end

      it "sets the inverse relation" do
        expect(address_two.addressable).to eq(person)
      end
    end

    context "when the document is not bindable" do

      it "does nothing" do
        expect(person.addresses).to receive(:<<).never
        binding.bind_one(address)
      end
    end
  end
end
