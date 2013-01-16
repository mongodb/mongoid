require "spec_helper"

describe Mongoid::Atomic::Paths::Embedded::Many do

  let(:person) do
    Person.new
  end

  let(:address) do
    Address.new(street: "Strassmannstr.")
  end

  let(:phone) do
    Phone.new(number: '+33123456789')
  end

  before do
    person.addresses << address
  end

  let(:many) do
    described_class.new(address)
  end

  describe "#delete_modifier" do

    it "returns $pull" do
      many.delete_modifier.should eq("$pull")
    end
  end

  describe "#document" do

    it "returns the document" do
      many.document.should eq(address)
    end
  end

  describe "#insert_modifier" do

    it "returns $push" do
      many.insert_modifier.should eq("$push")
    end
  end

  describe "#path" do

    context "when the document is embedded one level" do

      it "returns the name of the relation" do
        many.path.should eq("addresses")
      end
    end

    context "when the document is embedded multiple levels" do

      let(:location) do
        Location.new(name: "home")
      end

      before do
        address.locations << location
      end

      let(:many) do
        described_class.new(location)
      end

      it "returns the nested path to the relation" do
        many.path.should eq("addresses.locations")
      end
    end
  end

  describe "#position" do

    context "when the document is embedded one level" do

      context "with a relation with :store_as option" do
        let(:many) do
          described_class.new(phone)
        end

        before do
          person.phones << phone
        end
        it "return the name of the store_as in relation" do
          many.position.should eq("mobile_phones")
        end
      end

      it "returns the name of the relation" do
        many.position.should eq("addresses")
      end
    end

    context "when the document is embedded multiple levels" do

      let(:location) do
        Location.new(name: "home")
      end

      before do
        address.locations << location
        address.new_record = false
        location.new_record = false
      end

      let(:many) do
        described_class.new(location)
      end

      it "returns the nested position to the relation" do
        many.position.should eq("addresses.0.locations.0")
      end
    end
  end

  describe "#selector" do

    context "when the document is embedded one level" do

      it "returns the the hash with parent selector" do
        many.selector.should eq(
          { "_id" => person._id, "addresses._id" => address._id }
        )
      end
    end

    context "when the document is embedded multiple levels" do

      let(:location) do
        Location.new(name: "home")
      end

      before do
        address.locations << location
        address.new_record = false
        address.post_persist
        location.new_record = false
        location.post_persist
      end

      let(:many) do
        described_class.new(location)
      end

      it "returns the hash with all parent selectors" do
        many.selector.should eq(
          {
            "_id" => person._id,
            "addresses._id" => address._id,
            "addresses.0.locations._id" => location._id
          }
        )
      end
    end
  end
end
