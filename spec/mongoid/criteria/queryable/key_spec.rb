require "spec_helper"

describe Origin::Key do

  describe "#initialize" do

    let(:key) do
      described_class.new("field", :__union__, "$all")
    end

    it "sets the name" do
      expect(key.name).to eq("field")
    end

    it "sets the operator" do
      expect(key.operator).to eq("$all")
    end

    it "sets the strategy" do
      expect(key.strategy).to eq(:__union__)
    end
  end

  describe "#__expr_part__" do

    let(:key) do
      described_class.new("field", :__union__, "$all")
    end

    let(:specified) do
      key.__expr_part__([ 1, 2 ])
    end

    it "returns the name plus operator and value" do
      expect(specified).to eq({ "field" => { "$all" => [ 1, 2 ] }})
    end
  end

  describe '#hash' do
    let(:key) do
      described_class.new("field", :__union__, "$all")
    end

    let(:other) do
      described_class.new("field", :__union__, "$all")
    end

    it "returns the same hash for keys with the same attributes" do
      expect(key.hash).to eq(other.hash)
    end
  end
end
