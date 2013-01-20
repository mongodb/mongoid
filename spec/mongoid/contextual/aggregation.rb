require "spec_helper"

describe Mongoid::Contextual::Aggregation do

  let(:pipeline) do
    [
      {"$project" => { "name" => 1, "likes" => 1 }},
      {"$group" => { "_id" => "$name", "likes" => { "$sum" => "$likes" }}}
    ]
  end

  let!(:depeche_mode) do
    Band.create(name: "Depeche Mode", likes: 200)
  end

  let!(:tool) do
    Band.create(name: "Tool", likes: 100)
  end

  let!(:collection) do
    Band.collection
  end

  describe "#command" do

    let(:criteria) do
      Band.all
    end

    let(:aggregation) do
      described_class.new(collection, criteria, pipeline)
    end

    let(:base_command) do
      {
        aggregate: "bands",
        pipeline: pipeline.unshift({"$match" => {}})
      }
    end

    it "returns the db command" do
      aggregation.command.should eq(base_command)
    end
  end

  describe "#each" do

    let(:criteria) do
      Band.all
    end

    let(:aggregation) do
      described_class.new(collection, criteria, pipeline)
    end

    let(:results) do
      aggregation
    end

    it "iterates over the results" do
      results.entries.should eq([
        { "_id" => "Tool", "likes" => 100 },
        { "_id" => "Depeche Mode", "likes" => 200 }
      ])
    end
  end

  describe "#empty?" do

    let(:aggregation) do
      described_class.new(collection, criteria, pipeline)
    end

    context "when the aggregation has results" do

      let(:criteria) do
        Band.all
      end

      let(:results) do
        aggregation
      end

      it "returns false" do
        results.should_not be_empty
      end
    end

    context "when the aggregation has no results" do

      let(:criteria) do
        Band.where(name: "Pet Shop Boys")
      end

      let(:results) do
        aggregation
      end

      it "returns true" do
        results.should be_empty
      end
    end
  end
end
