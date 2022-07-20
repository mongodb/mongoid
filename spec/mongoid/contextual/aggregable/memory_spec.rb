# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Contextual::Aggregable::Memory do

  let(:context) do
    Mongoid::Contextual::Memory.new(criteria)
  end

  describe "#aggregates" do
    subject { context.aggregates(:likes) }

    context 'when no documents found' do
      let(:criteria) do
        Band.all.tap do |crit|
          crit.documents = []
        end
      end

      it do
        is_expected.to eq("count" => 0, "avg" => nil, "max" => nil, "min" => nil, "sum" => 0)
      end
    end

    context 'when documents found' do
      let(:criteria) do
        Band.all.tap do |crit|
          crit.documents = [ depeche, tool ]
        end
      end

      let!(:depeche) do
        Band.create(name: "Depeche Mode", likes: 1000)
      end

      let!(:tool) do
        Band.create(name: "Tool", likes: 500)
      end

      it do
        is_expected.to eq("count" => 0, "avg" => 750.0, "max" => 1000, "min" => 500, "sum" => 1500)
      end
    end
  end

  describe "#avg" do

    context "when the types are Integers" do

      let!(:depeche) do
        Band.create!(name: "Depeche Mode", likes: 1000)
      end

      let!(:tool) do
        Band.create!(name: "Tool", likes: 500)
      end

      let(:criteria) do
        Band.all.tap do |criteria|
          criteria.documents = [ depeche, tool ]
        end
      end

      let(:avg) do
        context.avg(:likes)
      end

      it "returns the avg of the provided field" do
        expect(avg).to eq(750)
      end

      it 'returns a float' do
        avg.should be_a(Float)
      end

      context 'when integers are negative' do

        let!(:depeche) do
          Band.create!(name: "Depeche Mode", likes: -1000)
        end

        it "returns the avg of the provided field" do
          expect(avg).to eq(-250)
        end

        it 'returns a float' do
          avg.should be_a(Float)
        end
      end
    end

    context "when the types are Floats" do

      let!(:depeche) do
        Band.create!(name: "Depeche Mode", rating: 10)
      end

      let!(:tool) do
        Band.create!(name: "Tool", rating: 5)
      end

      let(:criteria) do
        Band.all.tap do |criteria|
          criteria.documents = [ depeche, tool ]
        end
      end

      let(:avg) do
        context.avg(:rating)
      end

      it "returns the avg of the provided field" do
        expect(avg).to eq(7.5)
      end
    end

    context "when no documents match" do

      let!(:depeche) do
        Band.create!(name: "Depeche Mode", likes: 1000)
      end

      let(:criteria) do
        Band.where(name: "New Order")
      end

      let(:avg) do
        context.avg(:likes)
      end

      it "returns nil" do
        expect(avg).to be_nil
      end
    end

    context "when there are a mix of types" do

      let!(:bands) do
        [ Band.create!(name: "The Flaming Lips", mojo: 7.7),
          Band.create!(name: "Spirit of the Beehive", mojo: 10),
          Band.create!(name: "Justin Bieber", mojo: nil) ]
      end

      let(:criteria) do
        Band.all.tap do |criteria|
          criteria.documents = bands
        end
      end

      let(:avg) do
        context.avg(:mojo)
      end

      it "coerces types to calculate avg" do
        expect(avg).to eq(8.85)
      end

      it "database only averages Numeric types" do
        expect(Band.all.avg(:mojo)).to be_within(0.000001).of(8.85)
      end
    end

    context "when there no numeric values" do

      let!(:bands) do
        [ Band.create!(name: "Justin Bieber", mojo: nil) ]
      end

      let(:criteria) do
        Band.all.tap do |criteria|
          criteria.documents = bands
        end
      end

      let(:avg) do
        context.avg(:mojo)
      end

      it "returns avg as nil" do
        expect(avg).to be_nil
      end

      it "database returns avg as nil" do
        expect(Band.all.avg(:mojo)).to eq(nil)
      end
    end
  end

  describe "#max" do

    let!(:depeche) do
      Band.create!(name: "Depeche Mode", likes: 1000)
    end

    let!(:tool) do
      Band.create!(name: "Tool", likes: 500)
    end

    let(:criteria) do
      Band.all.tap do |crit|
        crit.documents = [ depeche, tool ]
      end
    end

    context "when provided a Symbol" do

      let(:max) do
        context.max(:likes)
      end

      it "returns the max of the provided field" do
        expect(max).to eq(1000)
      end

      context "when no documents match" do

        let(:criteria) do
          Band.where(name: "New Order")
        end

        let(:max) do
          context.max(:likes)
        end

        it "returns nil" do
          expect(max).to be_nil
        end
      end

      context "when there are a mix of types" do

        let!(:bands) do
          [ Band.create!(name: "The Flaming Lips", mojo: 7.7),
            Band.create!(name: "Spirit of the Beehive", mojo: 10),
            Band.create!(name: "Justin Bieber", mojo: nil) ]
        end

        let(:criteria) do
          Band.all.tap do |criteria|
            criteria.documents = bands
          end
        end

        let(:max) do
          context.max(:mojo)
        end

        it "coerces types to calculate max" do
          expect(max).to eq 10
          expect(max).to be_a Integer
        end
      end

      context "when there no numeric values" do

        let!(:bands) do
          [ Band.create!(name: "Justin Bieber", mojo: nil) ]
        end

        let(:criteria) do
          Band.all.tap do |criteria|
            criteria.documents = bands
          end
        end

        let(:max) do
          context.avg(:mojo)
        end

        it "returns max as nil" do
          expect(max).to be_nil
        end
      end
    end

    context "when provided a block" do

      let(:max) do
        context.max do |a, b|
          a.likes <=> b.likes
        end
      end

      it "returns the document with the max value for the field" do
        expect(max).to eq(depeche)
      end
    end
  end

  describe "#min" do

    let!(:depeche) do
      Band.create!(name: "Depeche Mode", likes: 1000)
    end

    let!(:tool) do
      Band.create!(name: "Tool", likes: 500)
    end

    let(:criteria) do
      Band.all.tap do |crit|
        crit.documents = [ depeche, tool ]
      end
    end

    context "when provided a Symbol" do

      let(:min) do
        context.min(:likes)
      end

      it "returns the min of the provided field" do
        expect(min).to eq(500)
      end

      context "when no documents match" do

        let(:criteria) do
          Band.where(name: "New Order")
        end

        let(:min) do
          context.min(:likes)
        end

        it "returns nil" do
          expect(min).to be_nil
        end
      end

      context "when there are a mix of types" do

        let!(:bands) do
          [ Band.create!(name: "The Flaming Lips", mojo: 7.7),
            Band.create!(name: "Spirit of the Beehive", mojo: 10),
            Band.create!(name: "Justin Bieber", mojo: nil) ]
        end

        let(:criteria) do
          Band.all.tap do |criteria|
            criteria.documents = bands
          end
        end

        let(:min) do
          context.min(:mojo)
        end

        it "coerces types to calculate min" do
          expect(min).to eq 7.7
          expect(min).to be_a Float
        end
      end

      context "when there no numeric values" do

        let!(:bands) do
          [ Band.create!(name: "Justin Bieber", mojo: nil) ]
        end

        let(:criteria) do
          Band.all.tap do |criteria|
            criteria.documents = bands
          end
        end

        let(:min) do
          context.min(:mojo)
        end

        it "returns min as nil" do
          expect(min).to be_nil
        end
      end
    end

    context "when provided a block" do

      let(:min) do
        context.min do |a, b|
          a.likes <=> b.likes
        end
      end

      it "returns the document with the min value for the field" do
        expect(min).to eq(tool)
      end
    end
  end

  describe "#sum" do

    let!(:depeche) do
      Band.create!(name: "Depeche Mode", likes: 1000)
    end

    let!(:tool) do
      Band.create!(name: "Tool", likes: 500)
    end

    let(:criteria) do
      Band.all.tap do |crit|
        crit.documents = [ depeche, tool ]
      end
    end

    context 'when values are integers' do

      let(:sum) do
        context.sum(:likes)
      end

      shared_examples 'sums and returns an integer' do
        it 'sums' do
          sum.should == 1500
        end

        it 'returns integer' do
          sum.should be_a(Integer)
        end
      end

      include_examples 'sums and returns an integer'

      context 'when values are numeric strings' do

        let!(:depeche) do
          Band.create!(name: "Depeche Mode", likes: '1000')
        end

        include_examples 'sums and returns an integer'
      end

      context 'when values are negative integers' do

        let!(:depeche) do
          Band.create!(name: "Depeche Mode", likes: -1000)
        end

        shared_examples 'sums and returns an integer' do
          it 'sums' do
            sum.should == -500
          end

          it 'returns integer' do
            sum.should be_a(Integer)
          end
        end

        include_examples 'sums and returns an integer'

        context 'when values are negative numeric strings' do

          let!(:depeche) do
            Band.create!(name: "Depeche Mode", likes: '-1000')
          end

          include_examples 'sums and returns an integer'
        end
      end
    end

    context 'when values are floats' do

      let!(:depeche) do
        Band.create!(name: "Depeche Mode", likes: 1000.0)
      end

      let(:sum) do
        context.sum(:likes)
      end

      it 'sums' do
        sum.should == 1500
      end

      it 'returns integer' do
        sum.should be_a(Integer)
      end
    end

    context "when provided a Symbol" do

      let(:sum) do
        context.sum(:likes)
      end

      it "returns the sum of the provided field" do
        expect(sum).to eq(1500)
      end

      context "when no documents match" do

        let(:criteria) do
          Band.where(name: "New Order")
        end

        let(:sum) do
          context.sum(:likes)
        end

        it "returns zero" do
          expect(sum).to eq(0)
        end
      end

      context "when there are a mix of types" do

        let!(:bands) do
          [ Band.create!(name: "The Flaming Lips", mojo: 7.7),
            Band.create!(name: "Spirit of the Beehive", mojo: 10),
            Band.create!(name: "Justin Bieber", mojo: nil) ]
        end

        let(:criteria) do
          Band.all.tap do |criteria|
            criteria.documents = bands
          end
        end

        let(:sum) do
          context.sum(:mojo)
        end

        it "coerces types to calculate sum" do
          expect(sum).to eq 17.7
          expect(sum).to be_a Float
        end

        it "database only sums Float and Integer types" do
          expect(Band.all.sum(:mojo)).to be_within(Float::EPSILON).of(17.7)
        end
      end

      context "when there no numeric values" do

        let!(:bands) do
          [ Band.create!(name: "Justin Bieber", mojo: nil) ]
        end

        let(:criteria) do
          Band.all.tap do |criteria|
            criteria.documents = bands
          end
        end

        let(:sum) do
          context.sum(:mojo)
        end

        it "returns sum as zero" do
          expect(sum).to eq 0
        end

        it "database returns sum as zero" do
          expect(Band.all.sum(:mojo)).to eq(0)
        end
      end
    end

    context "when provided a block" do

      let(:sum) do
        context.sum(&:likes)
      end

      it "returns the sum for the provided block" do
        expect(sum).to eq(1500)
      end
    end
  end
end
