require "spec_helper"

describe Mongoid::Atomic::Paths::Root do

  let(:person) do
    Person.new
  end

  let(:root) do
    described_class.new(person)
  end

  describe "#document" do

    it "returns the document" do
      expect(root.document).to eq(person)
    end
  end

  describe "#path" do

    it "returns an empty string" do
      expect(root.path).to be_empty
    end
  end

  describe "#position" do

    it "returns an empty string" do
      expect(root.position).to be_empty
    end
  end

  describe "#insert_modifier" do

    let(:address) do
      person.addresses.build
    end

    let(:root) do
      described_class.new(address)
    end

    it "raises a mixed relations error" do
      expect { root.insert_modifier }.to raise_error(Mongoid::Errors::InvalidPath)
    end
  end
end
