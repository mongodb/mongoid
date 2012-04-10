require "spec_helper"

describe Mongoid::Contextual::Aggregable::Memory do

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
          Band.all.tap do |criteria|
            criteria.documents = [ depeche, tool ]
          end
        end

        let(:context) do
          Mongoid::Contextual::Memory.new(criteria)
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
          Mongoid::Contextual::Memory.new(criteria)
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
        Band.all.tap do |crit|
          crit.documents = [ depeche, tool ]
        end
      end

      let(:context) do
        Mongoid::Contextual::Memory.new(criteria)
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
            Mongoid::Contextual::Memory.new(criteria)
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
        Band.all.tap do |crit|
          crit.documents = [ depeche, tool ]
        end
      end

      let(:context) do
        Mongoid::Contextual::Memory.new(criteria)
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
            Mongoid::Contextual::Memory.new(criteria)
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
        Band.all.tap do |crit|
          crit.documents = [ depeche, tool ]
        end
      end

      let(:context) do
        Mongoid::Contextual::Memory.new(criteria)
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
            Mongoid::Contextual::Memory.new(criteria)
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
