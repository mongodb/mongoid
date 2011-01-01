require "spec_helper"

describe Mongoid::Relations::Builders::Referenced::In do

  describe "#build" do

    let(:game) do
      Game.new
    end

    context "when no document found in the database" do

      context "when the id is nil" do

        it "returns nil" do
          game.person.should be_nil
        end
      end

      context "when the id is incorrect" do

        before do
          game.person_id = BSON::ObjectId.new
        end

        it "returns nil" do
          game.person.should be_nil
        end
      end
    end
  end
end
