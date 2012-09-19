require "spec_helper"

describe Mongoid::Contextual::MapReduce do

  let(:map) do
    %Q{
    function() {
      emit(this.name, { likes: this.likes });
    }}
  end

  let(:reduce) do
    %Q{
    function(key, values) {
      var result = { likes: 0 };
      values.forEach(function(value) {
        result.likes += value.likes;
      });
      return result;
    }}
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

    let(:map_reduce) do
      described_class.new(collection, criteria, map, reduce)
    end

    let(:base_command) do
      {
          mapreduce: "bands",
          map: map,
          reduce: reduce,
          query: {}
      }
    end

    it "returns the db command" do
      map_reduce.command.should eq(base_command)
    end

    context "with sort" do
      let(:criteria) do
        Band.order_by(name: -1)
      end

      it "returns the db command with a sort option" do
        map_reduce.command.should eq(base_command.merge(sort: {'name' => -1}))
      end
    end

    context "with limit" do
      let(:criteria) do
        Band.limit(10)
      end

      it "returns the db command with a limit option" do
        map_reduce.command.should eq(base_command.merge(limit: 10))
      end
    end
  end

  describe "#counts" do

    let(:criteria) do
      Band.all
    end

    let(:map_reduce) do
      described_class.new(collection, criteria, map, reduce)
    end

    let(:counts) do
      map_reduce.out(inline: 1).counts
    end

    it "returns the map/reduce counts" do
      counts.should eq({
        "input" => 2,
        "emit" => 2,
        "reduce" => 0,
        "output" => 2
      })
    end
  end

  describe "#each" do

    let(:criteria) do
      Band.all
    end

    let(:map_reduce) do
      described_class.new(collection, criteria, map, reduce)
    end

    context "when the map/reduce is inline" do

      let(:results) do
        map_reduce.out(inline: 1)
      end

      it "iterates over the results" do
        results.entries.should eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }},
          { "_id" => "Tool", "value" => { "likes" => 100 }}
        ])
      end
    end

    context "when the map/reduce is a collection" do

      let(:results) do
        map_reduce.out(replace: "mr-output")
      end

      it "iterates over the results" do
        results.entries.should eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }},
          { "_id" => "Tool", "value" => { "likes" => 100 }}
        ])
      end
    end

    context "when no output is provided" do

      it "raises an error" do
        expect {
          map_reduce.entries
        }.to raise_error(Mongoid::Errors::NoMapReduceOutput)
      end
    end

    context "when no results are returned" do

      let(:results) do
        map_reduce.out(replace: "mr-output-two")
      end

      before do
        Band.delete_all
      end

      it "does not raise an error" do
        results.entries.should be_empty
      end
    end
  end

  describe "#emitted" do

    let(:criteria) do
      Band.all
    end

    let(:map_reduce) do
      described_class.new(collection, criteria, map, reduce)
    end

    let(:emitted) do
      map_reduce.out(inline: 1).emitted
    end

    it "returns the emitted counts" do
      emitted.should eq(2)
    end
  end

  describe "#empty?" do

    let(:map_reduce) do
      described_class.new(collection, criteria, map, reduce)
    end

    context "when the map/reduce has results" do

      let(:criteria) do
        Band.all
      end

      let(:results) do
        map_reduce.out(inline: 1)
      end

      it "returns false" do
        results.should_not be_empty
      end
    end

    context "when the map/reduce has no results" do

      let(:criteria) do
        Band.where(name: "Pet Shop Boys")
      end

      let(:results) do
        map_reduce.out(inline: 1)
      end

      it "returns true" do
        results.should be_empty
      end
    end
  end

  describe "#finalize" do

    let(:criteria) do
      Band.all
    end

    let(:map_reduce) do
      described_class.new(collection, criteria, map, reduce)
    end

    let(:finalized) do
      map_reduce.finalize("testing")
    end

    it "sets the finalize command" do
      finalized.command[:finalize].should eq("testing")
    end
  end

  describe "#input" do

    let(:criteria) do
      Band.all
    end

    let(:map_reduce) do
      described_class.new(collection, criteria, map, reduce)
    end

    let(:input) do
      map_reduce.out(inline: 1).input
    end

    it "returns the input counts" do
      input.should eq(2)
    end
  end

  describe "#js_mode" do

    let(:criteria) do
      Band.all
    end

    let(:map_reduce) do
      described_class.new(collection, criteria, map, reduce)
    end

    let(:results) do
      map_reduce.out(inline: 1).js_mode
    end

    it "adds the jsMode flag to the command" do
      results.command[:jsMode].should be_true
    end
  end

  describe "#out" do

    let(:criteria) do
      Band.all
    end

    let(:map_reduce) do
      described_class.new(collection, criteria, map, reduce)
    end

    context "when providing inline" do

      let(:out) do
        map_reduce.out(inline: 1)
      end

      it "sets the out command" do
        out.command[:out].should eq(inline: 1)
      end
    end

    context "when not providing inline" do

      context "when the value is a symbol" do

        let(:out) do
          map_reduce.out(replace: :test)
        end

        it "sets the out command value to a string" do
          out.command[:out].should eq(replace: "test")
        end
      end
    end
  end

  describe "#output" do

    let(:criteria) do
      Band.all
    end

    let(:map_reduce) do
      described_class.new(collection, criteria, map, reduce)
    end

    let(:output) do
      map_reduce.out(inline: 1).output
    end

    it "returns the output counts" do
      output.should eq(2)
    end
  end

  describe "#reduced" do

    let(:criteria) do
      Band.all
    end

    let(:map_reduce) do
      described_class.new(collection, criteria, map, reduce)
    end

    let(:reduced) do
      map_reduce.out(inline: 1).reduced
    end

    it "returns the reduce counts" do
      reduced.should eq(0)
    end
  end

  describe "#scope" do

    let(:criteria) do
      Band.all
    end

    let(:map_reduce) do
      described_class.new(collection, criteria, map, reduce)
    end

    let(:finalize) do
      %Q{
      function(key, value) {
        value.global = test;
        return value;
      }}
    end

    let(:results) do
      map_reduce.out(inline: 1).scope(test: 5).finalize(finalize)
    end

    it "adds the variables to the global js scope" do
      results.first["value"]["global"].should eq(5)
    end
  end

  describe "#time" do

    let(:criteria) do
      Band.all
    end

    let(:map_reduce) do
      described_class.new(collection, criteria, map, reduce)
    end

    let(:time) do
      map_reduce.out(inline: 1).time
    end

    it "returns the execution time" do
      time.should_not be_nil
    end
  end

  describe "#execute" do

    let(:criteria) do
      Band.all
    end

    let(:map_reduce) do
      described_class.new(collection, criteria, map, reduce)
    end

    let(:execution_results) do
      map_reduce.out(inline: 1).execute
    end

    it "returns a hash" do
      execution_results.should be_a_kind_of Hash
    end
  end

  describe "#inspect" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    let(:out) do
      { inline: 1 }
    end

    let(:map_reduce) do
      described_class.new(collection, criteria, map, reduce).out(out)
    end

    let(:inspection) do
      map_reduce.inspect
    end

    it "returns a string" do
      inspection.should be_a_kind_of String
    end

    it "includes the criteria selector" do
      inspection.should include("selector:")
    end

    it "includes the class" do
      inspection.should include("class:")
    end

    it "includes the map function" do
      inspection.should include("map:")
    end

    it "includes the reduce function" do
      inspection.should include("reduce:")
    end

    it "includes the finalize function" do
      inspection.should include("finalize:")
    end

    it "includes the out option" do
      inspection.should include("out:")
    end
  end
end
