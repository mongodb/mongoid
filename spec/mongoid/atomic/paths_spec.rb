require "spec_helper"

describe Mongoid::Atomic::Paths do

  let(:person) do
    Person.new
  end

  let(:address) do
    Address.new(street: "testing")
  end

  let(:location) do
    Location.new
  end

  let(:name) do
    Name.new
  end

  describe "#.atomic_delete_modifier" do

    before do
      person.addresses << address
      person.name = name
    end

    context "when document is an embeds_one" do

      it "returns $unset" do
        name.atomic_delete_modifier.should eq("$unset")
      end
    end

    context "when document is an embeds_many" do

      it "returns $pull" do
        address.atomic_delete_modifier.should eq("$pull")
      end
    end
  end

  describe "#.atomic_insert_modifier" do

    before do
      person.addresses << address
      person.name = name
    end

    context "when document is an embeds_one" do

      it "returns $set" do
        name.atomic_insert_modifier.should eq("$set")
      end
    end

    context "when document is an embeds_many" do

      it "returns $push" do
        address.atomic_insert_modifier.should eq("$push")
      end
    end
  end

  describe "#.atomic_path" do

    context "when the document is a parent" do

      it "returns an empty string" do
        person.atomic_path.should be_empty
      end
    end

    context "when the document is embedded" do

      before do
        person.addresses << address
      end

      it "returns the inverse_of value of the association" do
        address.atomic_path.should eq("addresses")
      end
    end

    context "when document embedded multiple levels" do

      before do
        address.locations << location
        person.addresses << address
      end

      it "returns the JSON notation to the document" do
        location.atomic_path.should eq("addresses.locations")
      end
    end
  end

  describe "#.atomic_selector" do

    context "when the document is a parent" do

      it "returns an id.atomic_selector" do
        person.atomic_selector.should eq({ "_id" => person.id })
      end
    end

    context "when the document is embedded" do

      before do
        person.addresses << address
      end

      it "returns the association with id.atomic_selector" do
        address.atomic_selector.should eq(
          { "_id" => person.id, "addresses._id" => address.id }
        )
      end
    end

    context "when document embedded multiple levels" do

      before do
        address.locations << location
        person.addresses << address
      end

      it "returns the JSON notation to the document with ids" do
        location.atomic_selector.should eq(
          {
            "_id" => person.id,
            "addresses._id" => address.id,
            "addresses.locations._id" => location.id
          }
        )
      end
    end
  end

  describe "#.atomic_position" do

    context "when the document is a parent" do

      it "returns an empty string" do
        person.atomic_position.should be_empty
      end
    end

    context "when the document is embedded" do

      before do
        person.addresses << address
      end

      context "when the document is new" do

        it "returns the.atomic_path without index" do
          address.atomic_position.should eq("addresses")
        end
      end

      context "when the document is not new" do

        before do
          address.instance_variable_set(:@new_record, false)
        end

        it "returns the.atomic_path plus index" do
          address.atomic_position.should eq("addresses.0")
        end
      end
    end

    context "when document embedded multiple levels" do

      let(:other) do
        Location.new
      end

      before do
        address.locations << [ other, location ]
        address.instance_variable_set(:@new_record, false)
        person.addresses << address
      end

      context "when the document is new" do

        it "returns the.atomic_path with parent indexes" do
          location.atomic_position.should eq("addresses.0.locations")
        end
      end

      context "when the document is not new" do

        before do
          location.instance_variable_set(:@new_record, false)
        end

        it "returns the.atomic_path plus index" do
          location.atomic_position.should eq("addresses.0.locations.1")
        end
      end
    end
  end

  describe "#.atomic_path" do

    context "when the document is a parent" do

      it "returns an empty string" do
        person.atomic_path.should be_empty
      end
    end

    context "when the document is embedded" do

      before do
        person.addresses << address
      end

      context "when the document is not new" do

        before do
          address.instance_variable_set(:@new_record, false)
        end

        it "returns the.atomic_path without the index" do
          address.atomic_path.should eq("addresses")
        end

        context "and there are 10 or more documents" do

          before do
            10.times do
              person.addresses << address
            end
          end

          it "returns the.atomic_path without the index" do
            address.atomic_path.should eq("addresses")
          end
        end
      end
    end

    context "when document embedded multiple levels" do

      let(:other) do
        Location.new
      end

      before do
        address.locations << [ other, location ]
        address.instance_variable_set(:@new_record, false)
        person.addresses << address
      end

      context "when the document is not new" do

        before do
          location.instance_variable_set(:@new_record, false)
        end

        it "returns the.atomic_path plus index" do
          location.atomic_path.should eq("addresses.0.locations")
        end

      end
    end
  end
end
