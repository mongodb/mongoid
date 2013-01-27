require "spec_helper"

describe Mongoid::Atomic do

  describe "#add_atomic_pull" do

    let!(:person) do
      Person.create
    end

    let(:address) do
      person.addresses.create
    end

    let(:location) do
      address.locations.create
    end

    before do
      person.add_atomic_pull(address)
    end

    it "adds the document to the delayed atomic pulls" do
      person.delayed_atomic_pulls["addresses"].should eq([ address ])
    end

    it "flags the document for destruction" do
      address.should be_flagged_for_destroy
    end
  end

  describe "#add_atomic_unset" do

    let!(:person) do
      Person.new
    end

    let(:name) do
      person.build_name
    end

    before do
      person.add_atomic_unset(name)
    end

    it "adds the document to the delayed atomic unsets" do
      person.delayed_atomic_unsets["name"].should eq([ name ])
    end

    it "flags the document for destruction" do
      name.should be_flagged_for_destroy
    end
  end

  describe "#atomic_prefix" do

    context "when the document is the root" do

      let(:band) do
        Band.new
      end

      it "returns an empty string" do
        band.atomic_prefix.should eq("")
      end
    end

    context "when the document is embedded" do

      let(:band) do
        Band.create(name: "Tool")
      end

      let!(:record) do
        band.records.create(name: "Undertow")
      end

      context "when embedded with 10 other documents" do
        context "when using the positional operator" do
          it "returns the update selector with positional operator" do
            10.times { |i| band.records.create(name: i.to_s) }
            band.records.last.atomic_prefix.should eq("records.$")
          end
        end
      end

      context "when embedded with 100 other documents" do
        context "when using the positional operator" do
          it "returns the update selector with positional operator" do
            100.times { |i| band.records.create(name: i.to_s) }
            band.records.last.atomic_prefix.should eq("records.$")
          end
        end
      end

      context "when embedded one level" do

        context "when using the positional operator" do

          it "returns the update selector with positional operator" do
            record.atomic_prefix.should eq("records.$")
          end
        end
      end

      context "when embedded multiple levels" do

        let!(:track) do
          record.tracks.create(name: "Sober")
        end

        context "when using the positional operator" do

          it "returns the update selector with positional operator" do
            track.atomic_prefix.should eq("records.$.tracks.0")
          end
        end
      end
    end
  end

  describe "#atomic_updates" do

    context "when the document is persisted" do

      let(:person) do
        Person.create
      end

      context "when the document is modified" do

        before do
          person.title = "Sir"
        end

        it "returns the atomic updates" do
          person.atomic_updates.should eq({ "$set" => { "title" => "Sir" }})
        end

        context "when an embeds many child is added" do

          let!(:address) do
            person.addresses.build(street: "Oxford St")
          end

          it "returns a $set and $pushAll for modifications" do
            person.atomic_updates.should eq(
              {
                "$set" => { "title" => "Sir" },
                "$pushAll" => { "addresses" => [
                    { "_id" => "oxford-st", "street" => "Oxford St" }
                  ]}
              }
            )
          end
        end

        context "when an embeds one child is added" do

          let!(:name) do
            person.build_name(first_name: "Lionel")
          end

          it "returns a $set for modifications" do
            person.atomic_updates.should eq(
              {
                "$set" => {
                  "title" => "Sir",
                  "name" => { "_id" => "Lionel-", "first_name" => "Lionel" }
                }
              }
            )
          end
        end

        context "when an existing embeds many gets modified" do

          let!(:address) do
            person.addresses.create(street: "Oxford St")
          end

          before do
            address.street = "Bond St"
          end

          context "when asking for the updates from the root" do

            it "returns the $set with correct position and modifications" do
              person.atomic_updates.should eq(
                { "$set" => { "title" => "Sir", "addresses.0.street" => "Bond St" }}
              )
            end
          end

          context "when asking for the updates from the child" do

            it "returns the $set with correct position and modifications" do
              address.atomic_updates.should eq(
                { "$set" => { "addresses.$.street" => "Bond St" }}
              )
            end
          end

          context "when an existing 2nd level embedded child gets modified" do

            let!(:location) do
              address.locations.create(name: "Home")
            end

            before do
              location.name = "Work"
            end

            context "when asking for the updates from the root" do

              it "returns the $set with correct positions and modifications" do
                person.atomic_updates.should eq(
                  { "$set" => {
                    "title" => "Sir",
                    "addresses.0.street" => "Bond St",
                    "addresses.0.locations.0.name" => "Work" }
                  }
                )
              end
            end

            context "when asking for the updates from the 1st level child" do

              it "returns the $set with correct positions and modifications" do
                address.atomic_updates.should eq(
                  { "$set" => {
                    "addresses.$.street" => "Bond St",
                    "addresses.$.locations.0.name" => "Work" }
                  }
                )
              end
            end

            context "when asking for the updates from the 2nd level child" do

              it "returns the $set with correct positions and modifications" do
                location.atomic_updates.should eq(
                  { "$set" => {
                    "addresses.$.locations.0.name" => "Work" }
                  }
                )
              end
            end
          end

          context "when a 2nd level embedded child gets added" do

            let!(:location) do
              address.locations.build(name: "Home")
            end

            context "when asking for the updates from the root" do

              it "returns the $set with correct positions and modifications" do
                person.atomic_updates.should eq(
                  {
                    "$set" => {
                      "title" => "Sir",
                      "addresses.0.street" => "Bond St"
                    },
                    conflicts: {
                      "$pushAll" => {
                        "addresses.0.locations" => [{ "_id" => location.id, "name" => "Home" }]
                      }
                    }
                  }
                )
              end
            end

            context "when asking for the updates from the 1st level child" do

              it "returns the $set with correct positions and modifications" do
                address.atomic_updates.should eq(
                  {
                    "$set" => {
                      "addresses.$.street" => "Bond St"
                    },
                    conflicts: {
                      "$pushAll" => {
                        "addresses.$.locations" => [{ "_id" => location.id, "name" => "Home" }]
                      }
                    }
                  }
                )
              end
            end
          end

          context "when an embedded child gets unset" do

            before do
              person.attributes = { addresses: nil }
            end

            let(:updates) do
              person.atomic_updates
            end

            it "returns the $set for the first level and $unset for other." do
              updates.should eq({
                "$unset" => { "addresses" => true },
                "$set" => { "title" => "Sir" }
              })
            end
          end

          context "when adding a new second level child" do

            let!(:new_address) do
              person.addresses.build(street: "Another")
            end

            let!(:location) do
              new_address.locations.build(name: "Home")
            end

            context "when asking for the updates from the root document" do

              it "returns the $set for 1st level and other for the 2nd level" do
                person.atomic_updates.should eq(
                  {
                    "$set" => {
                      "title" => "Sir",
                      "addresses.0.street" => "Bond St"
                    },
                    conflicts: {
                      "$pushAll" => {
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
                  }
                )
              end
            end

            context "when asking for the updates from the 1st level document" do

              it "returns the $set for 1st level and other for the 2nd level" do
                address.atomic_updates.should eq(
                  { "$set" => { "addresses.$.street" => "Bond St" }}
                )
              end
            end
          end

          context "when adding a new child beetween two existing and updating one of them" do

            let!(:new_address) do
              person.addresses.build(street: "Ipanema")
            end

            let!(:location) do
              new_address.locations.build(name: "Home")
            end

            before do
              person.addresses[0] = new_address
              person.addresses[1] = address
            end

            it "returns the $set for 1st and 2nd level and other for the 3nd level" do
              person.atomic_updates.should eq(
                {
                  "$set" => {
                    "title" => "Sir"
                  },
                  "$pushAll" => {
                    "addresses" => [{
                      "_id" => new_address.id,
                      "street" => "Ipanema",
                      "locations" => [
                        "_id" => location.id,
                        "name" => "Home"
                      ]
                    }]
                  },
                  conflicts: {
                    "$set" => { "addresses.0.street"=>"Bond St" }
                  }
                }
              )
            end
          end
        end

        context "when adding new embedded docs at multiple levels" do

          let!(:address) do
            person.addresses.build(street: "Another")
          end

          let!(:location) do
            address.locations.build(name: "Home")
          end

          it "returns the proper $sets and $pushAlls for all levels" do
            person.atomic_updates.should eq(
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
            )
          end
        end
      end
    end
  end
end
