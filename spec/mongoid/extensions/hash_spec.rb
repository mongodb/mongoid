require "spec_helper"

describe Mongoid::Extensions::Hash do

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
