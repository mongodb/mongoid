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

  describe "#atomic_delete_modifier" do

    before do
      person.addresses << address
      person.name = name
    end

    context "when document is an embeds_one" do

      it "returns $unset" do
        expect(name.atomic_delete_modifier).to eq("$unset")
      end
    end

    context "when document is an embeds_many" do

      it "returns $pull" do
        expect(address.atomic_delete_modifier).to eq("$pull")
      end
    end
  end

  describe "#atomic_insert_modifier" do

    before do
      person.addresses << address
      person.name = name
    end

    context "when document is an embeds_one" do

      it "returns $set" do
        expect(name.atomic_insert_modifier).to eq("$set")
      end
    end

    context "when document is an embeds_many" do

      it "returns $push" do
        expect(address.atomic_insert_modifier).to eq("$push")
      end
    end
  end

  describe "#atomic_path" do

    context "when the document is a parent" do

      it "returns an empty string" do
        expect(person.atomic_path).to be_empty
      end
    end

    context "when the document is embedded" do

      before do
        person.addresses << address
      end

      it "returns the inverse_of value of the association" do
        expect(address.atomic_path).to eq("addresses")
      end
    end

    context "when document embedded multiple levels" do

      before do
        address.locations << location
        person.addresses << address
      end

      it "returns the JSON notation to the document" do
        expect(location.atomic_path).to eq("addresses.locations")
      end
    end
  end

  describe "#atomic_selector" do

    context "when the document is a parent" do

      it "returns an id.atomic_selector" do
        expect(person.atomic_selector).to eq({ "_id" => person.id })
      end
    end

    context "when the document is embedded" do

      before do
        person.addresses << address
      end

      it "returns the association with id.atomic_selector" do
        expect(address.atomic_selector).to eq(
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
        expect(location.atomic_selector).to eq(
          {
            "_id" => person.id,
            "addresses._id" => address.id,
            "addresses.locations._id" => location.id
          }
        )
      end
    end
  end

  describe "#atomic_position" do

    context "when the document is a parent" do

      it "returns an empty string" do
        expect(person.atomic_position).to be_empty
      end
    end

    context "when the document is embedded" do

      before do
        person.addresses << address
      end

      context "when the document is new" do

        it "returns the.atomic_path without index" do
          expect(address.atomic_position).to eq("addresses")
        end
      end

      context "when the document is not new" do

        before do
          address.instance_variable_set(:@new_record, false)
        end

        it "returns the.atomic_path plus index" do
          expect(address.atomic_position).to eq("addresses.0")
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
          expect(location.atomic_position).to eq("addresses.0.locations")
        end
      end

      context "when the document is not new" do

        before do
          location.instance_variable_set(:@new_record, false)
        end

        it "returns the.atomic_path plus index" do
          expect(location.atomic_position).to eq("addresses.0.locations.1")
        end
      end
    end
  end

  describe "#atomic_path" do

    context "when the document is a parent" do

      it "returns an empty string" do
        expect(person.atomic_path).to be_empty
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
          expect(address.atomic_path).to eq("addresses")
        end

        context "and there are 10 or more documents" do

          before do
            10.times do
              person.addresses << address
            end
          end

          it "returns the.atomic_path without the index" do
            expect(address.atomic_path).to eq("addresses")
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
          expect(location.atomic_path).to eq("addresses.0.locations")
        end
      end
    end
  end
end
