require "spec_helper"

describe Mongoid::Attributes::Processing do

  describe "#process_attributes" do

    let(:building) do
      Building.new
    end

    context "when setting embedded documents via the parent" do

      let(:attributes) do
        {
          building_address: { city: "Berlin" },
          contractors: [{ name: "Joe" }]
        }
      end

      context "when providing a role" do

        context "when creating new documents" do

          before do
            building.process_attributes(attributes, :admin, true)
          end

          let(:building_address) do
            building.building_address
          end

          let(:contractor) do
            building.contractors.first
          end

          context "when the child fields are accessible to the role" do

            it "sets the fields on the 1-1 child" do
              building_address.city.should eq("Berlin")
            end

            it "sets the fields on the 1-n child" do
              contractor.name.should eq("Joe")
            end
          end

          context "when updating the document" do

            let(:updates) do
              {
                building_address: { city: "Kiew" },
                contractors: [{ name: "Jim" }]
              }
            end

            before do
              building.process_attributes(updates, :admin, true)
            end

            it "updates the 1-1 child" do
              building_address.city.should eq("Kiew")
            end

            it "updates the 1-n child" do
              contractor.name.should eq("Jim")
            end
          end
        end
      end

      context "when turning off mass assignment" do

        context "when creating new documents" do

          before do
            building.process_attributes(attributes, :default, false)
          end

          let(:building_address) do
            building.building_address
          end

          let(:contractor) do
            building.contractors.first
          end

          context "when the child fields are accessible to the role" do

            it "sets the fields on the 1-1 child" do
              building_address.city.should eq("Berlin")
            end

            it "sets the fields on the 1-n child" do
              contractor.name.should eq("Joe")
            end
          end

          context "when updating the document" do

            let(:updates) do
              {
                building_address: { city: "Kiew" },
                contractors: [{ name: "Jim" }]
              }
            end

            before do
              building.process_attributes(updates, :default, false)
            end

            it "updates the 1-1 child" do
              building_address.city.should eq("Kiew")
            end

            it "updates the 1-n child" do
              contractor.name.should eq("Jim")
            end

            context "with a key that is not a valid ruby identifier" do
              let(:dynamic_updates) do
                {
                  building_address: { :"postal-code" => "V8N 1A1" },
                  contractors: [{ :"license number" => "12345" }]
                }
              end

              before do
                building.process_attributes(dynamic_updates, :default, false)
              end

              it "updates the 1-1 child" do
                building_address['postal-code'].should eq("V8N 1A1")
              end

              it "updates the 1-n child" do
                contractor['license number'].should eq("12345")
              end

              it "correctly handles a second call to #process_attributes" do
                building.process_attributes(dynamic_updates, :default, false)
              end
            end

          end
        end
      end
    end
  end
end
