require "spec_helper"

describe Mongoid::Atomic::Paths::Embedded::One do

  let(:person) do
    Person.new
  end

  let(:name) do
    Name.new(first_name: "Syd")
  end

  before do
    person.name = name
  end

  let(:one) do
    described_class.new(name)
  end

  describe "#delete_modifier" do

    it "returns $unset" do
      expect(one.delete_modifier).to eq("$unset")
    end
  end

  describe "#document" do

    it "returns the document" do
      expect(one.document).to eq(name)
    end
  end

  describe "#insert_modifier" do

    it "returns $set" do
      expect(one.insert_modifier).to eq("$set")
    end
  end

  describe "#path" do

    context "when the document is embedded one level" do

      it "returns the name of the relation" do
        expect(one.path).to eq("name")
      end
    end

    context "when the document is embedded multiple levels" do

      let(:phone) do
        Phone.new(number: "404-555-1212")
      end

      let(:country_code) do
        CountryCode.new(code: 1)
      end

      before do
        phone.country_code = country_code
        person.phone_numbers << phone
      end

      let(:one) do
        described_class.new(country_code)
      end

      it "returns the nested path to the relation" do
        expect(one.path).to eq("phone_numbers.country_code")
      end
    end
  end

  describe "#position" do

    context "when the document is embedded one level" do

      it "returns the name of the relation" do
        expect(one.position).to eq("name")
      end
    end

    context "when the document is embedded multiple levels" do

      let(:phone) do
        Phone.new(number: "404-555-1212")
      end

      let(:country_code) do
        CountryCode.new(code: 1)
      end

      before do
        phone.country_code = country_code
        person.phone_numbers << phone
        phone.new_record = false
      end

      let(:one) do
        described_class.new(country_code)
      end

      it "returns the nested position to the relation" do
        expect(one.position).to eq("phone_numbers.0.country_code")
      end
    end
  end
end
