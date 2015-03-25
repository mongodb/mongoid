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

describe BSON::Document do

  describe "#symbolize_keys" do

    let(:doc) do
      described_class.new("foo" => "bar")
    end

    it "returns key as symbol" do
      expect(doc.symbolize_keys.keys).to eq [:foo]
    end
  end
end
