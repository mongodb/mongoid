# frozen_string_literal: true

require "spec_helper"

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
