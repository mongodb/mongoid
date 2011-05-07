require "spec_helper"

describe Mongoid::Atomicity do

  describe "#_updates" do

    context "when the document is persisted" do

      let(:person) do
        Person.create(:ssn => "231-11-9956")
      end

      context "when the document is modified" do

        before do
          person.title = "Sir"
          person.ssn = nil
        end

        it "returns the atomic updates" do
          person._updates.should == { "$set" => { "title" => "Sir" }, "$unset" => {"ssn" => 1 } }
        end

        context "when an embeds many child is added" do

          let!(:address) do
            person.addresses.build(:street => "Oxford St")
          end

          it "returns a $set, $unset and $pushAll for modifications" do
            person._updates.should ==
              {
                "$set" => { "title" => "Sir" },
                "$unset" => {"ssn" => 1 },
                "$pushAll" => { "addresses" => [
                    { "_id" => "oxford-st", "street" => "Oxford St" }
                  ]}
              }
          end
        end

        context "when an embeds one child is added" do

          let!(:name) do
            person.build_name(:first_name => "Lionel")
          end

          it "returns a $set and $unset for modifications" do
            person._updates.should ==
              {
                "$set" => {
                  "title" => "Sir",
                  "name" => { "_id" => "lionel", "first_name" => "Lionel" }
                },
                "$unset" => {"ssn" => 1 }
              }
          end
        end

        context "when an existing embeds many gets modified" do

          let!(:address) do
            person.addresses.create(:street => "Oxford St", :post_code => 90210)
          end

          before do
            address.street = "Bond St"
            address.post_code = nil
          end

          it "returns the $set and $unset with correct position and modifications" do
            person._updates.should ==
              { "$set"   => { "title" => "Sir", "addresses.0.street" => "Bond St" },
                "$unset" => { "ssn" => 1, "addresses.0.post_code" => 1 } }
          end

          context "when an existing 2nd level embedded child gets modified" do

            let!(:location) do
              address.locations.create(:name => "Home", :style => "Art Deco")
            end

            before do
              location.name = "Work"
              location.style = nil
            end

            it "returns the $set and $unset with correct positions and modifications" do
              person._updates.should ==
                { "$set" => {
                    "title" => "Sir",
                    "addresses.0.street" => "Bond St",
                    "addresses.0.locations.0.name" => "Work" },
                  "$unset" => {
                    "ssn" => 1,
                    "addresses.0.post_code" => 1,
                    "addresses.0.locations.0.style" => 1
                  }
                }
            end
          end

          context "when a 2nd level embedded child gets added" do

            let!(:location) do
              address.locations.build(:name => "Home")
            end

            it "returns the $set and $unset with correct positions and modifications" do
              person._updates.should ==
                {
                  "$set" => {
                    "title" => "Sir",
                    "addresses.0.street" => "Bond St"
                  },
                  "$unset" => {
                    "ssn" => 1,
                    "addresses.0.post_code" => 1
                  },
                  :other => {
                    "addresses.0.locations" => [{ "_id" => location.id, "name" => "Home" }]
                  }
                }
            end
          end

          context "when adding a new second level child" do

            let!(:new_address) do
              person.addresses.build(:street => "Another")
            end

            let!(:location) do
              new_address.locations.build(:name => "Home")
            end

            it "returns the $set and $unset for 1st level and other for the 2nd level" do
              person._updates.should ==
                {
                  "$set" => {
                    "title" => "Sir",
                    "addresses.0.street" => "Bond St"
                  },
                  "$unset" => {
                    "ssn" => 1,
                    "addresses.0.post_code" => 1
                  },
                  :other => {
                    "addresses" => [{
                      "_id" => new_address.id,
                      "street" => "Another",
                      "locations" => [
                        "_id" => location.id,
                        "name" => "Home"
                      ]
                    }]
                  }
                }
            end
          end
        end

        context "when adding new embedded docs at multiple levels" do

          let!(:address) do
            person.addresses.build(:street => "Another")
          end

          let!(:location) do
            address.locations.build(:name => "Home")
          end

          it "returns the proper $sets and $pushAlls for all levels" do
            person._updates.should ==
              {
                "$set" => {
                  "title" => "Sir"
                },
                "$unset" => {
                  "ssn" => 1
                },
                "$pushAll" => {
                  "addresses" => [{
                    "_id" => address.id,
                    "street" => "Another",
                    "locations" => [
                      "_id" => location.id,
                      "name" => "Home"
                    ]
                  }]
                }
              }
          end
        end
      end
    end
  end
end
