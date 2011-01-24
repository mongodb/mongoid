require "spec_helper"

describe Mongoid::Relations::Builders::Referenced::One do

  describe "#build" do

    let(:person) do
      Person.new
    end

    context "when the document is not found" do

      it "returns nil" do
        person.game.should be_nil
      end
    end
  end
end
