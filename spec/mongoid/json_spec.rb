require "spec_helper"

describe Mongoid::JSON do

  describe ".include_root_in_json" do

    let(:person) do
      Person.new
    end

    context "when config set to true" do

      before do
        Mongoid.include_root_in_json = true
      end

      it "returns true" do
        person.include_root_in_json.should be_true
      end
    end

    context "when config set to false" do

      before do
        Mongoid.include_root_in_json = false
      end

      it "returns false" do
        person.include_root_in_json.should be_false
      end
    end
  end
end
