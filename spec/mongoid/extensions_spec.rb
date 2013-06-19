require "spec_helper"

describe BSON::ObjectId do

  describe "#as_json" do

    let(:object_id) do
      described_class.new
    end

    it "returns the $oid plus string" do
      expect(object_id.as_json).to eq("$oid" => object_id.to_s)
    end
  end
end
