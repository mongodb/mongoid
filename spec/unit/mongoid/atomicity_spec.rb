require "spec_helper"

describe Mongoid::Atomicity do

  before do
    # Mongoid.master.connection.instance_variable_set(:@logger, Logger.new($stdout))
  end

  describe "#_updates" do

    context "when the document is persisted" do

      let(:person) do
        Person.create(:ssn => "231-11-9956")
      end

      context "when the document is modified" do

        before do
          person.title = "Sir"
        end

        it "returns the atomic updates" do
          person._updates.should == { "$set" => { "title" => "Sir" } }
        end

        context "when an embeds many child is added" do

          let!(:address) do
            person.addresses.build(:street => "Oxford St")
          end

          it "returns a $set and $pushAll for modifications" do
            person._updates.should ==
              {
                "$set" => {
                  "title" => "Sir",
                  "addresses.0.street" => "Bond St"
                },
                :other => {
                  "addresses.0.locations" => [{ "_id" => @location.id, "name" => "Work" }]
                }
              }
          end
        end

        context "when an embeds one child is added" do

          let!(:name) do
            person.build_name(:first_name => "Lionel")
          end

          it "returns a $set for modifications" do
            person._updates.should ==
              {
                "$set" => {
                  "title" => "Sir",
                  "name" => { "_id" => "lionel", "first_name" => "Lionel" }
                }
              }
          end
        end

        context "when an existing embeds many gets modified" do

          let!(:address) do
            person.addresses.create(:street => "Oxford St")
          end

          before do
            address.street = "Bond St"
          end

          it "returns the $set with correct position and modifications" do
            person._updates.should ==
              { "$set" => { "title" => "Sir", "addresses.0.street" => "Bond St" } }
          end

          context "when an existing 2nd level embedded child gets modified" do

            let!(:location) do
              address.locations.create(:name => "Home")
            end

            before do
              location.name = "Work"
            end

            it "returns the $set with correct positions and modifications" do
              person._updates.should ==
                { "$set" => {
                  "title" => "Sir",
                  "addresses.0.street" => "Bond St",
                  "addresses.0.locations.0.name" => "Work" }
                }
            end
          end

          context "when a 2nd level embedded child gets added" do

            let!(:location) do
              address.locations.build(:name => "Home")
            end

            it "returns the $set with correct positions and modifications" do
              person._updates.should ==
                {
                  "$set" => {
                    "title" => "Sir",
                    "addresses.0.street" => "Bond St"
                  },
                  "$pushAll" => {
                    "addresses.0.locations" => [{ "_id" => location.id, "name" => "Home" }]
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
                  "title" => "Sir",
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

          # it "returns the proper hash with locations and queue" do
            # @person._updates.should ==
              # {
                # "$set" => {
                  # "title" => "Sir",
                  # "addresses.0.street" => "Bond St"
                # },
                # :other => {
                  # "addresses" => [{
                    # "_id" => @new_address.id,
                    # "street" => "Another",
                    # "locations" => [
                      # "_id" => @location.id,
                      # "name" => "Home"
                    # ]
                  # }]
                # }
              # }
          # end
        # end
      # end
    # end
  end
end
