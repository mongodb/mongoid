require "spec_helper"

describe Mongoid::Criterion::Complex do

  let(:complex) do
    described_class.new(:key => :field, :operator => "gt")
  end

  describe "#initialize" do

    it "sets the key" do
      complex.key.should eq(:field)
    end

    it "sets the operator" do
      complex.operator.should == "gt"
    end
  end

  describe "#to_mongo_query" do
    it "creates a query" do
      complex.to_mongo_query(5).should == { "$gt" => 5}
      complex.operator.should eq("gt")
    end
  end

  describe "#to_s" do

    let(:complex) do
      described_class.new(:key => :field, :operator => "gt")
    end

    it "returns the name of the key" do
      complex.to_s.should eq("field")
    end
  end

  context "when comparing equivalent objects" do

    let(:equivalent_complex) do
      described_class.new(:key => :field, :operator => "gt")
    end

    it "is identifiable as equal" do
      complex.should eq(equivalent_complex)
    end

    it "hashes to the same value" do
      complex.hash.should eq(equivalent_complex.hash)
    end
  end

  context "when comparing different objects" do

    let(:different_complex) do
      described_class.new(:key => :field, :operator => "lt")
    end

    it "is identifiable as different" do
      complex.should_not eq(different_complex)
    end

    it "hashes to a different value" do
      complex.hash.should_not eq(different_complex.hash)
    end
  end
end
