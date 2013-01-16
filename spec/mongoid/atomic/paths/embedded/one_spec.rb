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
      one.delete_modifier.should eq("$unset")
    end
  end

  describe "#document" do

    it "returns the document" do
      one.document.should eq(name)
    end
  end

  describe "#insert_modifier" do

    it "returns $set" do
      one.insert_modifier.should eq("$set")
    end
  end

  describe "#path" do

    context "when the document is embedded one level" do

      it "returns the name of the relation" do
        one.path.should eq("name")
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
        one.path.should eq("phone_numbers.country_code")
      end
    end
  end

  describe "#position" do

    context "when the document is embedded one level" do

      it "returns the name of the relation" do
        one.position.should eq("name")
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
        one.position.should eq("phone_numbers.0.country_code")
      end
    end
  end

  describe "#selector" do

    context "when the document is embedded one level" do

      it "returns the the hash with parent selector" do
        one.selector.should eq({ "_id" => person._id, "name._id" => name._id })
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
        phone.post_persist
      end

      let(:one) do
        described_class.new(country_code)
      end

      it "returns the hash with all parent selectors" do
        one.selector.should eq(
          {
            "_id" => person._id,
            "phone_numbers._id" => phone._id,
            "phone_numbers.0.country_code._id" => country_code._id
          }
        )
      end
    end
  end
end
