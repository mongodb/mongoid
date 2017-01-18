require "spec_helper"

describe Mongoid::Contextual::GeoNear do

  describe "#average_distance" do

    let!(:collection) do
      Bar.collection
    end

    before do
      Bar.create_indexes
    end

    let!(:bar_one) do
      Bar.create(location: [ 52.30, 13.25 ])
    end

    let!(:bar_two) do
      Bar.create(location: [ 52.30, 13.35 ])
    end

    context "when results are returned" do

      let(:criteria) do
        Bar.all
      end

      let(:geo_near) do
        described_class.new(collection, criteria, [ 52, 13 ])
      end

      it "returns the average distance" do
        expect(geo_near.average_distance).to_not be_nil
      end
    end

    context "when no results are returned" do

      let(:criteria) do
        Bar.where(name: "Green Door")
      end

      let(:geo_near) do
        described_class.new(collection, criteria, [ 52, 13 ])
      end

      it "returns 0.0" do
        expect(geo_near.average_distance).to be_nil
      end
    end
  end

  describe "#each" do

    let!(:collection) do
      Bar.collection
    end

    before do
      Bar.create_indexes
    end

    let!(:bar_one) do
      Bar.create(location: [ 52.30, 13.25 ])
    end

    let!(:bar_two) do
      Bar.create(location: [ 52.30, 13.35 ])
    end

    context "when no options are provided" do

      let(:criteria) do
        Bar.all
      end

      let(:geo_near) do
        described_class.new(collection, criteria, [ 52, 13 ])
      end

      let(:results) do
        geo_near.entries
      end

      it "returns all the documents" do
        expect(results).to eq([ bar_one, bar_two ])
      end
    end

    context "when the criteria has a limit" do

      let(:criteria) do
        Bar.limit(1)
      end

      let(:geo_near) do
        described_class.new(collection, criteria, [ 52, 13 ])
      end

      let(:results) do
        geo_near.entries
      end

      it "returns the limited documents" do
        expect(results).to eq([ bar_one ])
      end
    end

    context "when providing a max distance" do

      let(:criteria) do
        Bar.all
      end

      let(:geo_near) do
        described_class.new(collection, criteria, [ 52, 13 ])
      end

      let(:results) do
        geo_near.max_distance(0.40).entries
      end

      it "returns the limited documents" do
        expect(results).to eq([ bar_one ])
      end
    end

    context "when spcifying spherical" do

      let(:criteria) do
        Bar.all
      end

      let(:geo_near) do
        described_class.new(collection, criteria, [ 52, 13 ])
      end

      let(:results) do
        geo_near.spherical.entries
      end

      it "returns the documents" do
        expect(results).to eq([ bar_one, bar_two ])
      end
    end

    context "when providing a distance multiplier" do

      let(:criteria) do
        Bar.all
      end

      let(:geo_near) do
        described_class.new(collection, criteria, [ 52, 13 ])
      end

      let(:results) do
        geo_near.distance_multiplier(6378.1).entries
      end

      it "returns the documents" do
        expect(results).to eq([ bar_one, bar_two ])
      end

      it "multiplies the distance factor" do
        expect(results.first.geo_near_distance.to_i).to eq(2490)
      end
    end

    context "when unique is false" do

      let(:criteria) do
        Bar.all
      end

      let(:geo_near) do
        described_class.new(collection, criteria, [ 52, 13 ])
      end

      let(:results) do
        geo_near.unique(false).entries
      end

      it "returns the documents" do
        expect(results).to eq([ bar_one, bar_two ])
      end
    end
  end

  describe "#empty?" do

    let!(:collection) do
      Bar.collection
    end

    before do
      Bar.create_indexes
    end

    let!(:bar_one) do
      Bar.create(location: [ 52.30, 13.25 ])
    end

    let!(:bar_two) do
      Bar.create(location: [ 52.30, 13.35 ])
    end

    let(:geo_near) do
      described_class.new(collection, criteria, [ 52, 13 ])
    end

    context "when the $geoNear has results" do

      let(:criteria) do
        Bar.all
      end

      it "returns false" do
        expect(geo_near).to_not be_empty
      end
    end

    context "when the map/reduce has no results" do

      let(:criteria) do
        Bar.where(name: "Halo")
      end

      it "returns true" do
        expect(geo_near).to be_empty
      end
    end
  end

  describe "#execute" do

    let!(:collection) do
      Bar.collection
    end

    before do
      Bar.create_indexes
    end

    let!(:bar_one) do
      Bar.create(location: [ 52.30, 13.25 ])
    end

    let!(:bar_two) do
      Bar.create(location: [ 52.30, 13.35 ])
    end

    let(:criteria) do
      Bar.all
    end

    let(:geo_near) do
      described_class.new(collection, criteria, [ 52, 13 ])
    end

    let(:execution_results) do
      geo_near.execute
    end

    it "returns a hash" do
      expect(execution_results).to be_a_kind_of(Hash)
    end
  end

  describe "#max_distance" do

    let!(:collection) do
      Bar.collection
    end

    before do
      Bar.create_indexes
    end

    let!(:bar_one) do
      Bar.create(location: [ 52.30, 13.25 ])
    end

    let!(:bar_two) do
      Bar.create(location: [ 52.30, 13.35 ])
    end

    context "when results are returned" do

      let(:criteria) do
        Bar.all
      end

      let(:geo_near) do
        described_class.new(collection, criteria, [ 52, 13 ])
      end

      it "returns the max distance" do
        expect(geo_near.max_distance).to_not be_nil
      end
    end

    context "when no results are returned" do

      let(:criteria) do
        Bar.where(name: "Green Door")
      end

      let(:geo_near) do
        described_class.new(collection, criteria, [ 52, 13 ])
      end

      it "returns 0.0" do
        expect(geo_near.max_distance).to eq(0.0)
      end
    end
  end

  describe "#min_distance" do

    let!(:collection) do
      Pub.collection
    end

    before do
      Pub.create_indexes
    end

    let!(:bar_one) do
      Pub.create(location: [ 52.30, 13.25 ])
    end

    let!(:bar_two) do
      Pub.create(location: [ 52.30, 13.35 ])
    end

    context "when results are returned" do

      let(:criteria) do
        Pub.all
      end

      let(:geo_near) do
        described_class.new(collection, criteria, [ 52, 13 ]).spherical.min_distance(0.0)
      end

      it "sets the min distance" do
        expect(geo_near.to_a).to include(bar_one)
        expect(geo_near.to_a).to include(bar_two)
      end
    end
  end

  describe "#inspect" do

    let!(:collection) do
      Bar.collection
    end

    before do
      Bar.create_indexes
    end

    let!(:bar_one) do
      Bar.create(location: [ 52.30, 13.25 ])
    end

    let!(:bar_two) do
      Bar.create(location: [ 52.30, 13.35 ])
    end

    let(:criteria) do
      Bar.all
    end

    let(:geo_near) do
      described_class.new(collection, criteria, [ 52, 13 ])
    end

    it "contains the selector" do
      expect(geo_near.inspect).to include("selector")
    end

    it "contains the class" do
      expect(geo_near.inspect).to include("class")
    end

    it "contains the near" do
      expect(geo_near.inspect).to include("near")
    end

    it "contains the multiplier" do
      expect(geo_near.inspect).to include("multiplier")
    end

    it "contains the max" do
      expect(geo_near.inspect).to include("max")
    end

    it "contains the unique" do
      expect(geo_near.inspect).to include("unique")
    end

    it "contains the spherical" do
      expect(geo_near.inspect).to include("spherical")
    end
  end

  describe "#time" do

    let!(:collection) do
      Bar.collection
    end

    before do
      Bar.create_indexes
    end

    let!(:bar_one) do
      Bar.create(location: [ 52.30, 13.25 ])
    end

    let!(:bar_two) do
      Bar.create(location: [ 52.30, 13.35 ])
    end

    let(:criteria) do
      Bar.all
    end

    let(:geo_near) do
      described_class.new(collection, criteria, [ 52, 13 ])
    end

    it "returns the execution time" do
      expect(geo_near.time).to_not be_nil
    end
  end

  describe "#empty_and_chainable" do

    let!(:collection) do
      Bar.collection
    end

    let(:criteria) do
      Bar.all
    end

    let(:geo_near) do
      described_class.new(collection, criteria, [ 52, 13 ])
    end

    it "returns true" do
      expect(geo_near.empty_and_chainable?).to be(true)
    end
  end
end
