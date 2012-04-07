require "spec_helper"

describe Mongoid::Contextual::Aggregable do

  describe "#aggregates" do

    context "when provided a single field" do

      let!(:depeche) do
        Band.create(name: "Depeche Mode", likes: 1000)
      end

      let!(:tool) do
        Band.create(name: "Tool", likes: 500)
      end

      let(:criteria) do
        Band.all
      end

      let(:context) do
        Mongoid::Contextual::Mongo.new(criteria)
      end

      context "when aggregating on a field that exists" do

        context "when more than 1 document is emitted" do

          let(:aggregates) do
            context.aggregates(:likes)
          end

          it "returns an avg" do
            aggregates["avg"].should eq(750)
          end

          it "returns a count" do
            aggregates["count"].should eq(2)
          end

          it "returns a max" do
            aggregates["max"].should eq(1000)
          end

          it "returns a min" do
            aggregates["min"].should eq(500)
          end

          it "returns a sum" do
            aggregates["sum"].should eq(1500)
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
            aggregates["avg"].should eq(1000)
          end

          it "returns a count" do
            aggregates["count"].should eq(1)
          end

          it "returns a max" do
            aggregates["max"].should eq(1000)
          end

          it "returns a min" do
            aggregates["min"].should eq(1000)
          end

          it "returns a sum" do
            aggregates["sum"].should eq(1000)
          end
        end
      end

      context "when the field does not exist" do

        let(:aggregates) do
          context.aggregates(:non_existant)
        end

        it "returns an avg" do
          aggregates["avg"].should eq(0)
        end

        it "returns a count" do
          aggregates["count"].should eq(2)
        end

        it "returns a max" do
          aggregates["max"].should be_nil
        end

        it "returns a min" do
          aggregates["min"].should be_nil
        end

        it "returns a sum" do
          aggregates["sum"].should eq(0)
        end
      end

      context "when there are no matching documents" do

        let(:criteria) do
          Band.where(name: "New Order")
        end

        let(:aggregates) do
          context.aggregates(:non_existant)
        end

        it "returns nil" do
          aggregates.should eq({ "count" => 0 })
        end
      end
    end
  end

  describe "#avg" do

    context "when provided a single field" do

      context "when there are matching documents" do

        let!(:depeche) do
          Band.create(name: "Depeche Mode", likes: 1000)
        end

        let!(:tool) do
          Band.create(name: "Tool", likes: 500)
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
          avg.should eq(750)
        end
      end

      context "when no documents match" do

        let!(:depeche) do
          Band.create(name: "Depeche Mode", likes: 1000)
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
          avg.should be_nil
        end
      end
    end
  end

  describe "#max" do

    context "when provided a single field" do

      let!(:depeche) do
        Band.create(name: "Depeche Mode", likes: 1000)
      end

      let!(:tool) do
        Band.create(name: "Tool", likes: 500)
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
          max.should eq(1000)
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
            max.should be_nil
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
          max.should eq(depeche)
        end
      end
    end
  end

  describe "#min" do

    context "when provided a single field" do

      let!(:depeche) do
        Band.create(name: "Depeche Mode", likes: 1000)
      end

      let!(:tool) do
        Band.create(name: "Tool", likes: 500)
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
          min.should eq(500)
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
            min.should be_nil
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
          min.should eq(tool)
        end
      end
    end
  end

  describe "#sum" do

    context "when provided a single field" do

      let!(:depeche) do
        Band.create(name: "Depeche Mode", likes: 1000)
      end

      let!(:tool) do
        Band.create(name: "Tool", likes: 500)
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
          sum.should eq(1500)
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

          it "returns nil" do
            sum.should be_nil
          end
        end
      end

      context "when provided a block" do

        let(:sum) do
          context.sum(&:likes)
        end

        it "returns the sum for the provided block" do
          sum.should eq(1500)
        end
      end
    end
  end
end
