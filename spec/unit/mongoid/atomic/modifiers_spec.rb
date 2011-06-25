require "spec_helper"

describe Mongoid::Atomic::Modifiers do

  let(:modifiers) do
    described_class.new
  end

  describe "#conflicting?" do

    context "when the sets contain a conflicting field" do

      before do
        modifiers.set({ "addresses.0.street" => "Tauentzienstr." })
      end

      it "returns true" do
        modifiers.should be_conflicting("addresses")
      end
    end

    context "when the sets do not contain a conflicting field" do

      before do
        modifiers.set({ "addresses.0.street" => "Tauentzienstr." })
      end

      context "when the field name is not similar" do

        it "returns false" do
          modifiers.should_not be_conflicting("title")
        end
      end

      context "when the field name is similar" do

        it "returns false" do
          modifiers.should_not be_conflicting("address")
        end
      end
    end
  end

  describe "#push" do

    context "when the pushes are empty" do

      before do
        modifiers.push({})
      end

      it "does not contain any push operations" do
        modifiers.should == {}
      end
    end

    context "when no conflicting modification is present" do

      context "when adding a single push" do

        let(:pushes) do
          { "addresses" => { "street" => "Oxford St" } }
        end

        before do
          modifiers.push(pushes)
        end

        it "adds the push all modifiers" do
          modifiers.should ==
            { "$pushAll" =>
              { "addresses" => [
                  { "street" => "Oxford St" }
                ]
              }
            }
        end
      end

      context "when adding to an existing push" do

        let(:push_one) do
          { "addresses" => { "street" => "Hobrechtstr." } }
        end

        let(:push_two) do
          { "addresses" => { "street" => "Pflugerstr." } }
        end

        before do
          modifiers.push(push_one)
          modifiers.push(push_two)
        end

        it "adds the push all modifiers" do
          modifiers.should ==
            { "$pushAll" =>
              { "addresses" => [
                  { "street" => "Hobrechtstr." },
                  { "street" => "Pflugerstr." }
                ]
              }
            }
        end
      end
    end

    context "when a conflicting modification exists" do

      let(:sets) do
        { "addresses.0.street" => "Bond" }
      end

      let(:pushes) do
        { "addresses" => { "street" => "Oxford St" } }
      end

      before do
        modifiers.set(sets)
        modifiers.push(pushes)
      end

      it "adds the push all modifiers to the conflicts hash" do
        modifiers.should ==
          { "$set" => { "addresses.0.street" => "Bond" },
            :other =>
            { "addresses" => [
                { "street" => "Oxford St" }
              ]
            }
          }
      end
    end
  end

  describe "#set" do

    describe "when adding to the root level" do

      context "when the sets have values" do

        let(:sets) do
          { "title" => "Sir" }
        end

        before do
          modifiers.set(sets)
        end

        it "adds the sets to the modifiers" do
          modifiers.should == { "$set" => { "title" => "Sir" } }
        end
      end

      context "when the sets are empty" do

        before do
          modifiers.set({})
        end

        it "does not contain set operations" do
          modifiers.should == {}
        end
      end
    end
  end
end
