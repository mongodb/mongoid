require "spec_helper"

describe Mongoid::Atomicity do

  describe "#_updates" do

    context "when the root and embedded documets have changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
        @person.instance_variable_set(:@new_record, false)
        @person.title = "Sir"
      end

      it "returns a hash of field names and new values" do
        @person._updates.should ==
          { "$set" => { "title" => "Sir" } }
      end

      context "with a new embedded document" do

        context "when the document is an embeds many" do

          before do
            @address = Address.new(:street => "Oxford St")
            @person.addresses << @address
          end

          it "returns a hash of field names and new values" do
            @person._updates.should ==
              {
                "$set" => { "title" => "Sir" },
                "$pushAll" => { "addresses" => [{ "_id" => "oxford-st", "street" => "Oxford St" }]}
              }
          end
        end

        context "when the document is an embeds one" do

          before do
            @name = Name.new(:first_name => "Lionel")
            @person.name = @name
          end

          it "returns a hash of field names and new values" do
            @person._updates.should ==
              {
                "$set" => {
                  "title" => "Sir",
                  "name" => { "_id" => "lionel", "first_name" => "Lionel" }
                },
              }
          end
        end
      end

      context "with an updated embedded document" do

        before do
          @address = Address.new(:street => "Oxford St")
          @person.addresses << @address
          @address.instance_variable_set(:@new_record, false)
          @address.street = "Bond St"
        end

        it "returns a hash of field names and new values" do
          @person._updates.should ==
            { "$set" => { "title" => "Sir", "addresses.0.street" => "Bond St" } }
        end

        context "with an multi-level updated embeded document" do

          before do
            @location = Location.new(:name => "Home")
            @location.instance_variable_set(:@new_record, false)
            @address.locations << @location
            @location.name = "Work"
          end

          it "returns the proper hash with locations" do
            @person._updates.should ==
              { "$set" => {
                "title" => "Sir",
                "addresses.0.street" => "Bond St",
                "addresses.0.locations.0.name" => "Work" }
              }
          end
        end

        context "with an multi-level new bottom embedded document" do

          before do
            @location = Location.new(:name => "Home")
            @address.locations << @location
            @location.name = "Work"
          end

          it "returns the proper hash with locations" do
            @person._updates.should ==
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

        context "with multi-level new documents" do

          before do
            @location = Location.new(:name => "Home")
            @new_address = Address.new(:street => "Another")
            @new_address.locations << @location
            @person.addresses << @new_address
          end

          it "returns the proper hash with locations" do
            @address.stubs(:_sets).returns({})
            @person._updates.should ==
              {
                "$set" => {
                  "title" => "Sir",
                },
                "$pushAll" => {
                  "addresses" => [{
                    "_id" => @new_address.id,
                    "street" => "Another",
                    "locations" => [
                      "_id" => @location.id,
                      "name" => "Home"
                    ]
                  }]
                }
              }
          end

          it "returns the proper hash with locations and queue" do
            @person._updates.should ==
              {
                "$set" => {
                  "title" => "Sir",
                  "addresses.0.street" => "Bond St"
                },
                :other => {
                  "addresses" => [{
                    "_id" => @new_address.id,
                    "street" => "Another",
                    "locations" => [
                      "_id" => @location.id,
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
