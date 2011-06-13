require "spec_helper"

describe Mongoid::Criterion::Complex do

  let(:complex) { Mongoid::Criterion::Complex.new(:key => :field, :operator => "gt") }

  describe "#initialize" do

    it "sets the key" do
      complex.key.should == :field
    end

    it "sets the operator" do
      complex.operator.should == "gt"
    end
  end

  context "when creating query" do
    let(:test_query) { 10 }

    it "operator should be present" do
      complex.to_mongo_query(test_query).keys.first.should == "$#{complex.operator}"
    end

    it "should have correct query" do
      complex.to_mongo_query(test_query)["$#{complex.operator}"].should == test_query
    end
  end

  context "when comparing equivalent objects" do
    let(:equivalent_complex) { Mongoid::Criterion::Complex.new(:key => :field, :operator => "gt") }

    it "is identifiable as equal" do
      complex.should == equivalent_complex
    end

    it "hashes to the same value" do
      complex.hash.should == equivalent_complex.hash
    end
  end

  context "when comparing different objects" do
    let(:different_complex) { Mongoid::Criterion::Complex.new(:key => :field, :operator => "lt") }

    it "is identifiable as different" do
      complex.should_not == different_complex
    end

    it "hashes to a different value" do
      complex.hash.should_not == different_complex.hash
    end
  end
end
