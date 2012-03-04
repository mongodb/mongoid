require "spec_helper"

describe Mongoid::Extensions::Hash do

  describe "#_deep_copy" do

    let(:value) do
      { key: "value" }
    end

    let(:hash) do
      { test: value }
    end

    let(:copy) do
      hash._deep_copy
    end

    it "returns an equal object" do
      copy.should eq(hash)
    end

    it "returns a new instance" do
      copy.should_not equal(hash)
    end

    it "clones nested values" do
      copy[:test].should_not equal(value)
    end
  end

  describe "#expand_complex_criteria" do

    context "when the criterion is simple" do

      let(:hash) do
        { :age.gt => 40, title: "Title" }
      end

      let(:expanded) do
        hash.expand_complex_criteria
      end

      it "expands the simple criteiron" do
        expanded.should eq({ age: { "$gt" => 40 }, title: "Title" })
      end
    end

    context "when the criterion has multiple expansions" do

      let(:hash) do
        { :age.gt => 40, :age.lt => 45 }
      end

      let(:expanded) do
        hash.expand_complex_criteria
      end

      it "expands all criterion" do
        expanded.should eq({ age: { "$gt" => 40, "$lt" => 45 }})
      end
    end

    context "when the criterion is nested" do

      let(:hash) do
        { "person.videos".to_sym.matches => { :year.gt => 2000 } }
      end

      let(:expanded) do
        hash.expand_complex_criteria
      end

      it "expands the nested criterion" do
        expanded.should eq(
          { :"person.videos" => { "$elemMatch" => { year: { "$gt" => 2000 }}}}
        )
      end
    end
  end
end
