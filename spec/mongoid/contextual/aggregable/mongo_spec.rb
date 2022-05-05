# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Contextual::Aggregable::Mongo do

  describe "#aggregates" do

    context "when provided a single field" do

      let!(:depeche) do
        Band.create!(name: "Depeche Mode", likes: 1000, years: 1000)
      end

      let!(:tool) do
        Band.create!(name: "Tool", likes: 500, years: 800)
      end

      let(:criteria) do
        Band.all
      end

      let(:context) do
        Mongoid::Contextual::Mongo.new(criteria)
      end

      context "when aggregating on a field that exists" do

        context "when aggregating on an aliased field" do

          let(:aggregates) do
            context.aggregates(:years)
          end

          it "returns an avg" do
            expect(aggregates["avg"]).to eq(900)
          end

          it "returns a count of documents with that field" do
            expect(aggregates["count"]).to eq(2)
          end

          it "returns a max" do
            expect(aggregates["max"]).to eq(1000)
          end

          it "returns a min" do
            expect(aggregates["min"]).to eq(800)
          end

          it "returns a sum" do
            expect(aggregates["sum"]).to eq(1800)
          end
        end

        context "when more than 1 document is emitted" do

          let(:aggregates) do
            context.aggregates(:likes)
          end

          it "returns an avg" do
            expect(aggregates["avg"]).to eq(750)
          end

          it "returns a count of documents with that field" do
            expect(aggregates["count"]).to eq(2)
          end

          it "returns a max" do
            expect(aggregates["max"]).to eq(1000)
          end

          it "returns a min" do
            expect(aggregates["min"]).to eq(500)
          end

          it "returns a sum" do
            expect(aggregates["sum"]).to eq(1500)
          end
        end

        context "when only 1 document is emitted" do

          let(:criteria) do
            Band.where(name: "Depeche Mode")
          end

          let(:aggregates) do
            context.aggregates(:likes)
          end

          it "returns an avg" do
            expect(aggregates["avg"]).to eq(1000)
          end

          it "returns a count of documents with that field" do
            expect(aggregates["count"]).to eq(1)
          end

          it "returns a max" do
            expect(aggregates["max"]).to eq(1000)
          end

          it "returns a min" do
            expect(aggregates["min"]).to eq(1000)
          end

          it "returns a sum" do
            expect(aggregates["sum"]).to eq(1000)
          end
        end

        context "when only 1 document is emitted because of sorting, skip and limit" do

          let(:criteria) do
            Band.desc(:name).skip(1).limit(1)
          end

          let(:aggregates) do
            context.aggregates(:likes)
          end

          it "returns an avg" do
            expect(aggregates["avg"]).to eq(1000)
          end

          it "returns a count of documents with that field" do
            expect(aggregates["count"]).to eq(1)
          end

          it "returns a max" do
            expect(aggregates["max"]).to eq(1000)
          end

          it "returns a min" do
            expect(aggregates["min"]).to eq(1000)
          end

          it "returns a sum" do
            expect(aggregates["sum"]).to eq(1000)
          end
        end
      end

      context "when the field does not exist" do

        let(:aggregates) do
          context.aggregates(:non_existent)
        end

        it "returns an avg" do
          expect(aggregates["avg"]).to be_nil
        end

        it "returns a count of documents with that field" do
          expect(aggregates["count"]).to eq(0)
        end

        it "returns a max" do
          expect(aggregates["max"]).to be_nil
        end

        it "returns a min" do
          expect(aggregates["min"]).to be_nil
        end

        context "when broken_aggregables feature flag is not set" do
          config_override :broken_aggregables, false

          it "returns a sum" do
            expect(aggregates["sum"]).to eq 0
          end
        end

        context "when broken_aggregables feature flag is set" do
          config_override :broken_aggregables, true

          it "returns nil" do
            expect(aggregates["sum"]).to be_nil
          end
        end

      end

      context "when the field sometimes exists" do
        let!(:oasis) do
          Band.create!(name: "Oasis", likes: 50)
        end

        let!(:radiohead) do
          Band.create!(name: "Radiohead")
        end

        context "and the field doesn't exist on the last document" do
          let(:criteria) do
            Band.all
          end

          let(:context) do
            Mongoid::Contextual::Mongo.new(criteria)
          end

          let(:aggregates) do
            context.aggregates(:likes)
          end

          it "returns a min" do
            expect(aggregates["min"]).to eq(50)
          end

          it "returns a count of documents with that field" do
            expect(aggregates["count"]).to eq(3)
          end
        end

        context "and the field doesn't exist on the before-last document" do
          let!(:u2) do
            Band.create!(name: "U2", likes: 100)
          end

          let(:criteria) do
            Band.all
          end

          let(:context) do
            Mongoid::Contextual::Mongo.new(criteria)
          end

          let(:aggregates) do
            context.aggregates(:likes)
          end

          it "returns a min" do
            expect(aggregates["min"]).to eq(50)
          end

          it "returns a count of documents with that field" do
            expect(aggregates["count"]).to eq(4)
          end
        end
      end

      context "when there are no matching documents" do

        let(:criteria) do
          Band.where(name: "New Order")
        end

        let(:aggregates) do
          context.aggregates(:non_existent)
        end

        context "when broken_aggregables feature flag is not set" do
          config_override :broken_aggregables, false

          it "returns empty result" do
            expect(aggregates).to eq({ "count" => 0, "sum" => 0, "avg" => nil, "min" => nil, "max" => nil })
          end
        end

        context "when broken_aggregables feature flag is set" do
          config_override :broken_aggregables, true

          it "returns empty result" do
            expect(aggregates).to eq({ "count" => 0, "sum" => nil, "avg" => nil, "min" => nil, "max" => nil })
          end
        end
      end
    end
  end

  describe "#avg" do

    context "when provided a single field" do

      context "when there are matching documents" do

        let!(:depeche) do
          Band.create!(name: "Depeche Mode", likes: 1000)
        end

        let!(:tool) do
          Band.create!(name: "Tool", likes: 500)
        end

        let(:criteria) do
          Band.all
        end

        let(:context) do
          Mongoid::Contextual::Mongo.new(criteria)
        end

        let(:avg) do
          context.avg(:likes)
        end

        it "returns the avg of the provided field" do
          expect(avg).to eq(750)
        end
      end

      context "when no documents match" do

        let!(:depeche) do
          Band.create!(name: "Depeche Mode", likes: 1000)
        end

        let(:criteria) do
          Band.where(name: "New Order")
        end

        let(:context) do
          Mongoid::Contextual::Mongo.new(criteria)
        end

        let(:avg) do
          context.avg(:likes)
        end

        it "returns nil" do
          expect(avg).to be_nil
        end
      end
    end
  end

  describe "#max" do

    context 'when the field does not exist in any document' do

      let!(:depeche) do
        Band.create!(name: "Depeche Mode", likes: 1000)
      end

      let(:criteria) do
        Band.all
      end

      let(:context) do
        Mongoid::Contextual::Mongo.new(criteria)
      end

      let(:max) do
        context.max(:non_existent)
      end

      it 'returns nil' do
        expect(max).to be(nil)
      end
    end

    context "when provided a single field" do

      let!(:depeche) do
        Band.create!(name: "Depeche Mode", likes: 1000)
      end

      let!(:tool) do
        Band.create!(name: "Tool", likes: 500)
      end

      let(:criteria) do
        Band.all
      end

      let(:context) do
        Mongoid::Contextual::Mongo.new(criteria)
      end

      context "when provided a symbol" do

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

          let(:context) do
            Mongoid::Contextual::Mongo.new(criteria)
          end

          let(:max) do
            context.max(:likes)
          end

          it "returns nil" do
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
  end

  describe "#min" do

    context "when provided a single field" do

      let!(:depeche) do
        Band.create!(name: "Depeche Mode", likes: 1000)
      end

      let!(:tool) do
        Band.create!(name: "Tool", likes: 500)
      end

      let(:criteria) do
        Band.all
      end

      let(:context) do
        Mongoid::Contextual::Mongo.new(criteria)
      end

      context "when provided a symbol" do

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

          let(:context) do
            Mongoid::Contextual::Mongo.new(criteria)
          end

          let(:min) do
            context.min(:likes)
          end

          it "returns nil" do
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
  end

  describe "#sum" do

    context "when provided a single field" do

      let!(:depeche) do
        Band.create!(name: "Depeche Mode", likes: 1000)
      end

      let!(:tool) do
        Band.create!(name: "Tool", likes: 500)
      end

      let(:criteria) do
        Band.all
      end

      let(:context) do
        Mongoid::Contextual::Mongo.new(criteria)
      end

      context "when provided a symbol" do

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

          let(:context) do
            Mongoid::Contextual::Mongo.new(criteria)
          end

          let(:sum) do
            context.sum(:likes)
          end

          it "returns zero" do
            expect(sum).to eq(0)
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

  describe '#pipeline' do
    let(:context) { Mongoid::Contextual::Mongo.new(criteria) }
    let(:pipeline) { context.send(:pipeline, :likes) }
    subject(:stages) { pipeline.map {|s| s.keys.first } }

    context "with sort" do

      context "without limit or skip" do
        let(:criteria) { Band.desc(:name) }

        it 'should omit the $sort stage' do
          expect(stages).to eq %w[$match $group]
        end
      end

      context "with limit" do
        let(:criteria) { Band.desc(:name).limit(1) }

        it 'should include the $sort stage' do
          expect(stages).to eq %w[$match $sort $limit $group]
        end
      end

      context "with skip" do
        let(:criteria) { Band.desc(:name).skip(1) }

        it 'should include the $sort stage' do
          expect(stages).to eq %w[$match $sort $skip $group]
        end
      end

      context "with skip and skip" do
        let(:criteria) { Band.desc(:name).limit(1).skip(1) }

        it 'should include the $sort stage' do
          expect(stages).to eq %w[$match $sort $skip $limit $group]
        end
      end
    end

    context "without sort" do

      context "without limit or skip" do
        let(:criteria) { Band.all }

        it 'should omit the $sort stage' do
          expect(stages).to eq %w[$match $group]
        end
      end

      context "with limit" do
        let(:criteria) { Band.limit(1) }

        it 'should include the $sort stage' do
          expect(stages).to eq %w[$match $limit $group]
        end
      end

      context "with skip" do
        let(:criteria) { Band.skip(1) }

        it 'should include the $sort stage' do
          expect(stages).to eq %w[$match $skip $group]
        end
      end

      context "with skip and skip" do
        let(:criteria) { Band.limit(1).skip(1) }

        it 'should include the $sort stage' do
          expect(stages).to eq %w[$match $skip $limit $group]
        end
      end
    end
  end
end
