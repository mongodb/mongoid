require "spec_helper"

describe Mongoid::Atomicity do

  describe "#_updates" do

    context "when the document is persisted" do

      let(:person) do
        Person.new
      end

      before do
        person.instance_variable_set(:@new_record, false)
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

          it "returns the entire hierarchy updates" do
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
            # TODO: Durran: This is saving - should not be.
            person.build_name(:first_name => "Lionel")
          end

          it "returns the entire hierarchy updates" do
            person._updates.should ==
              {
                "$set" => {
                  "title" => "Sir",
                  "name" => { "_id" => "lionel", "first_name" => "Lionel" }
                }
              }
          end
        end
      end
    end

      # context "with an updated embedded document" do

        # before do
          # @address = Address.new(:street => "Oxford St")
          # @person.addresses << @address
          # @address.instance_variable_set(:@new_record, false)
          # @address.street = "Bond St"
        # end

        # it "returns a hash of field names and new values" do
          # @person._updates.should ==
            # { "$set" => { "title" => "Sir", "addresses.0.street" => "Bond St" } }
        # end

        # context "with an multi-level updated embeded document" do

          # before do
            # @location = Location.new(:name => "Home")
            # @location.instance_variable_set(:@new_record, false)
            # @address.locations << @location
            # @location.name = "Work"
          # end

          # it "returns the proper hash with locations" do
            # @person._updates.should ==
              # { "$set" => {
                # "title" => "Sir",
                # "addresses.0.street" => "Bond St",
                # "addresses.0.locations.0.name" => "Work" }
              # }
          # end
        # end

        # context "with an multi-level new bottom embedded document" do

          # before do
            # @location = Location.new(:name => "Home")
            # @address.locations << @location
            # @location.name = "Work"
          # end

          # it "returns the proper hash with locations" do
            # @person._updates.should ==
              # {
                # "$set" => {
                  # "title" => "Sir",
                  # "addresses.0.street" => "Bond St"
                # },
                # "$pushAll" => {
                  # "addresses.0.locations" => [{ "_id" => @location.id, "name" => "Work" }]
                # }
              # }
          # end
        # end

        # context "with multi-level new documents" do

          # before do
            # @location = Location.new(:name => "Home")
            # @new_address = Address.new(:street => "Another")
            # @new_address.locations << @location
            # @person.addresses << @new_address
          # end

          # it "returns the proper hash with locations" do
            # @address.stubs(:_sets).returns({})
            # @person._updates.should ==
              # {
                # "$set" => {
                  # "title" => "Sir",
                # },
                # "$pushAll" => {
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
