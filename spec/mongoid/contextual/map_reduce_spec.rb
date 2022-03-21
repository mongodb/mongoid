# frozen_string_literal: true

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
    Band.create!(name: "Depeche Mode", likes: 200)
  end

  let!(:tool) do
    Band.create!(name: "Tool", likes: 100)
  end

  let!(:collection) do
    Band.collection
  end

  let(:criteria) do
    Band.all
  end

  let(:map_reduce) do
    described_class.new(collection, criteria, map, reduce)
  end

  describe "#command" do

    let(:base_command) do
      {
          mapreduce: "bands",
          map: map,
          reduce: reduce,
          query: {}
      }
    end

    context "with sort" do

      let(:criteria) do
        Band.order_by(name: -1)
      end

      it "includes a sort option in the map reduce command" do
        expect(map_reduce.command[:sort]).to eq('name' => -1)
      end
    end

    context "with limit" do

      let(:criteria) do
        Band.limit(10)
      end

      it "returns the db command with a limit option" do
        expect(map_reduce.command[:limit]).to eq(10)
      end
    end
  end

  describe "#counts" do
    max_server_version '4.2'

    let(:criteria) do
      Band.all
    end

    let(:counts) do
      map_reduce.out(inline: 1).counts
    end

    it "returns the map/reduce counts" do
      expect(counts).to eq({
        "input" => 2,
        "emit" => 2,
        "reduce" => 0,
        "output" => 2
      })
    end
  end

  describe "#each" do

    context "when the map/reduce is inline" do

      let(:results) do
        map_reduce.out(inline: 1)
      end

      it "iterates over the results" do
        ordered_results = results.entries.sort_by { |doc| doc['_id'] }
        expect(ordered_results.entries).to eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }},
          { "_id" => "Tool", "value" => { "likes" => 100 }}
        ])
      end
    end

    context "when the map/reduce is a collection" do

      let(:results) do
        map_reduce.out(replace: "mr-output")
      end

      let(:expected_results) do
        [
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }},
          { "_id" => "Tool", "value" => { "likes" => 100 }}
        ]
      end

      it "iterates over the results" do
        ordered_results = results.entries.sort_by { |doc| doc['_id'] }
        expect(ordered_results).to eq(expected_results)
      end

      it 'outputs to the collection' do
        expect(results.entries).to eq(map_reduce.criteria.view.database["mr-output"].find.to_a)
      end
    end

    context "when no output is provided" do

      context "when the results are iterated" do

        it "raises an error" do
          expect {
            map_reduce.entries
          }.to raise_error(Mongoid::Errors::NoMapReduceOutput)
        end
      end

      context "when the statstics are requested" do
        max_server_version '4.2'

        it "raises an error" do
          expect {
            map_reduce.counts
          }.to raise_error(Mongoid::Errors::NoMapReduceOutput)
        end
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
        expect(results.entries).to be_empty
      end
    end

    context "when there is a collation on the criteria" do

      let(:map) do
        %Q{
         function() {
           emit(this.name, 1);
        }}
      end

      let(:reduce) do
        %Q{
         function(key, values) {
           return Array.sum(values);
        }}
      end

      let(:criteria) do
        Band.where(name: 'DEPECHE MODE').collation(locale: 'en_US', strength: 2)
      end

      it 'applies the collation' do
        expect(map_reduce.out(inline: 1).count).to eq(1)
      end
    end
  end

  describe "#emitted" do
    max_server_version '4.2'

    let(:emitted) do
      map_reduce.out(inline: 1).emitted
    end

    it "returns the emitted counts" do
      expect(emitted).to eq(2)
    end
  end

  describe "#empty?" do

    context "when the map/reduce has results" do

      let(:results) do
        map_reduce.out(inline: 1)
      end

      it "returns false" do
        expect(results).to_not be_empty
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
        expect(results).to be_empty
      end
    end
  end

  describe "#finalize" do

    let(:finalized) do
      map_reduce.finalize("testing")
    end

    it "sets the finalize command" do
      expect(finalized.command[:finalize]).to eq("testing")
    end
  end

  describe "#input" do
    max_server_version '4.2'

    let(:input) do
      map_reduce.out(inline: 1).input
    end

    it "returns the input counts" do
      expect(input).to eq(2)
    end
  end

  describe "#js_mode" do

    let(:results) do
      map_reduce.out(inline: 1).js_mode
    end

    it "adds the jsMode flag to the command" do
      expect(results.command[:jsMode]).to be true
    end
  end

  describe "#out" do

    context "when providing inline" do

      let(:out) do
        map_reduce.out(inline: 1)
      end

      it "sets the out command" do
        expect(out.command[:out][:inline]).to eq(1)
      end
    end

    context "when not providing inline" do

      context "when the value is a symbol" do

        let(:out) do
          map_reduce.out(replace: :test)
        end

        it "sets the out command value to a string" do
          expect(out.command[:out][:replace]).to eq('test')
        end
      end
    end
  end

  describe "#output" do
    max_server_version '4.2'

    let(:output) do
      map_reduce.out(inline: 1).output
    end

    it "returns the output counts" do
      expect(output).to eq(2)
    end
  end

  describe "#raw" do

    let(:client) do
      collection.database.client
    end

    context "when not specifying an out" do

      it "raises a NoMapReduceOutput error" do
        expect {
          map_reduce.raw
        }.to raise_error(Mongoid::Errors::NoMapReduceOutput)
      end
    end

    context "when providing replace" do

      let(:replace_map_reduce) do
        map_reduce.out(replace: 'output-collection')
      end

      context 'when a read preference is defined' do
        require_topology :replica_set
        # On 4.4 it seems the server inserts on the primary, not on the server
        # that executed the map/reduce.
        max_server_version '4.2'

        let(:criteria) do
          Band.all.read(mode: :secondary)
        end

        it "uses the read preference" do

          expect {
            replace_map_reduce.raw
          }.to raise_exception(Mongo::Error::OperationFailure)
        end
      end
    end
  end

  describe "#reduced" do
    max_server_version '4.2'

    let(:reduced) do
      map_reduce.out(inline: 1).reduced
    end

    it "returns the reduce counts" do
      expect(reduced).to eq(0)
    end
  end

  describe "#scope" do

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
      expect(results.first["value"]["global"]).to eq(5)
    end
  end

  describe "#time" do
    max_server_version '4.2'

    let(:time) do
      map_reduce.out(inline: 1).time
    end

    it "returns the execution time" do
      expect(time).to_not be_nil
    end
  end

  describe "#execute" do

    let(:execution_results) do
      map_reduce.out(inline: 1).execute
    end

    it "returns a hash" do
      expect(execution_results).to be_a_kind_of Hash
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
      expect(inspection).to be_a_kind_of String
    end

    it "includes the criteria selector" do
      expect(inspection).to include("selector:")
    end

    it "includes the class" do
      expect(inspection).to include("class:")
    end

    it "includes the map function" do
      expect(inspection).to include("map:")
    end

    it "includes the reduce function" do
      expect(inspection).to include("reduce:")
    end

    it "includes the finalize function" do
      expect(inspection).to include("finalize:")
    end

    it "includes the out option" do
      expect(inspection).to include("out:")
    end
  end
end
