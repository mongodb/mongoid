# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Atomic do

  describe "#add_atomic_pull" do

    let!(:person) do
      Person.create!
    end

    let(:address) do
      person.addresses.create!
    end

    let(:location) do
      address.locations.create!
    end

    before do
      person.add_atomic_pull(address)
    end

    it "adds the document to the delayed atomic pulls" do
      expect(person.delayed_atomic_pulls["addresses"]).to eq([ address ])
    end

    it "flags the document for destruction" do
      expect(address).to be_flagged_for_destroy
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
      expect(person.delayed_atomic_unsets["name"]).to eq([ name ])
    end

    it "flags the document for destruction" do
      expect(name).to be_flagged_for_destroy
    end
  end

  describe "#atomic_updates" do

    context "when the document is persisted" do

      let(:person) do
        Person.create!
      end

      context "when the document is modified" do

        before do
          person.title = "Sir"
        end

        it "returns the atomic updates" do
          expect(person.atomic_updates).to eq({ "$set" => { "title" => "Sir" }})
        end

        context "when an embeds many child is added" do

          let!(:address) do
            person.addresses.build(street: "Oxford St")
          end

          it "returns a $set and $push with $each for modifications" do
            expect(person.atomic_updates).to eq(
              {
                "$set" => { "title" => "Sir" },
                "$push" => { "addresses" => { "$each" => [
                    { "_id" => "oxford-st", "street" => "Oxford St" }
                  ] } }
              }
            )
          end
        end

        context "when an embeds one child is added" do

          let!(:name) do
            person.build_name(first_name: "Lionel")
          end

          it "returns a $set for modifications" do
            expect(person.atomic_updates).to eq(
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
            person.addresses.create!(street: "Oxford St")
          end

          before do
            address.street = "Bond St"
          end

          context "when asking for the updates from the root" do

            it "returns the $set with correct position and modifications" do
              expect(person.atomic_updates).to eq(
                { "$set" => { "title" => "Sir", "addresses.0.street" => "Bond St" }}
              )
            end
          end

          context "when asking for the updates from the child" do

            it "returns the $set with correct position and modifications" do
              expect(address.atomic_updates).to eq(
                { "$set" => { "addresses.0.street" => "Bond St" }}
              )
            end
          end

          context "when an existing 2nd level embedded child gets modified" do

            let!(:location) do
              address.locations.create!(name: "Home")
            end

            before do
              location.name = "Work"
            end

            context "when asking for the updates from the root" do

              it "returns the $set with correct positions and modifications" do
                expect(person.atomic_updates).to eq(
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
                expect(address.atomic_updates).to eq(
                  { "$set" => {
                    "addresses.0.street" => "Bond St",
                    "addresses.0.locations.0.name" => "Work" }
                  }
                )
              end
            end

            context "when asking for the updates from the 2nd level child" do

              it "returns the $set with correct positions and modifications" do
                expect(location.atomic_updates).to eq(
                  { "$set" => {
                    "addresses.0.locations.0.name" => "Work" }
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
                expect(person.atomic_updates).to eq(
                  {
                    "$set" => {
                      "title" => "Sir",
                      "addresses.0.street" => "Bond St"
                    },
                    conflicts: {
                      "$push" => {
                        "addresses.0.locations" => { '$each' => [{ "_id" => location.id, "name" => "Home" }] }
                      }
                    }
                  }
                )
              end
            end

            context "when asking for the updates from the 1st level child" do

              it "returns the $set with correct positions and modifications" do
                expect(address.atomic_updates).to eq(
                  {
                    "$set" => {
                      "addresses.0.street" => "Bond St"
                    },
                    conflicts: {
                      "$push" => {
                        "addresses.0.locations" => { '$each' => [{ "_id" => location.id, "name" => "Home" }] }
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
              expect(updates).to eq({
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
                expect(person.atomic_updates).to eq(
                  {
                    "$set" => {
                      "title" => "Sir",
                      "addresses.0.street" => "Bond St"
                    },
                    conflicts: {
                      "$push" => {
                        "addresses" => { '$each' => [{
                          "_id" => new_address.id,
                          "street" => "Another",
                          "locations" => [
                            "_id" => location.id,
                            "name" => "Home"
                          ]
                        }]}
                      }
                    }
                  }
                )
              end
            end

            context "when asking for the updates from the 1st level document" do

              it "returns the $set for 1st level and other for the 2nd level" do
                expect(address.atomic_updates).to eq(
                  { "$set" => { "addresses.0.street" => "Bond St" }}
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
              expect(person.atomic_updates).to eq(
                {
                  "$set" => {
                    "title" => "Sir"
                  },
                  "$push" => {
                    "addresses" => { '$each' => [{
                      "_id" => new_address.id,
                      "street" => "Ipanema",
                      "locations" => [
                        "_id" => location.id,
                        "name" => "Home"
                      ]
                    }] }
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

          it "returns the proper $sets and $pushes for all levels" do
            expect(person.atomic_updates).to eq(
              {
                "$set" => {
                  "title" => "Sir",
                },
                "$push" => {
                  "addresses" => { '$each' => [{
                    "_id" => address.id,
                    "street" => "Another",
                    "locations" => [
                      "_id" => location.id,
                      "name" => "Home"
                    ]
                  }] }
                }
              }
            )
          end
        end

        context 'when adding nested embedded docs and updating top level embedded doc' do
          let!(:truck) { Truck.create! }
          let!(:crate) { truck.crates.create!(volume: 1) }

          before do
            truck.crates.first.volume = 2
            truck.crates.first.toys.build(name: 'Bear')
            truck.crates.build
          end

          it 'correctly distributes the operations' do
            pending 'https://jira.mongodb.org/browse/MONGOID-4982'

            truck.atomic_updates.should == {
              '$set' => {'crates.0.volume' => 2},
              '$push' => {'crates.0.toys' => {'$each' => [crate.toys.first.attributes]}},
              conflicts: {
                '$push' => {'crates' => {'$each' => [truck.crates.last.attributes]}},
              },
            }
          end
        end
      end
    end

    context "when adding embedded documents with nil ids" do
      let(:account) { Account.create!(name: "acc") }

      before do
        account.memberships.build(id: nil, name: "m1")
        account.memberships.build(id: nil, name: "m2")
      end

      it "has the correct updates" do
        account.atomic_updates.should == {
          "$push" => {
            "memberships" => {
              "$each" => [
                { "_id" => nil, "name" => "m1" },
                { "_id" => nil, "name" => "m2" }
              ]
            }
          }
        }
      end
    end
  end
end
