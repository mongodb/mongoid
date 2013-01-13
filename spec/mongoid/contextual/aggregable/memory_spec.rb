require "spec_helper"

describe Mongoid::Contextual::Aggregable::Memory do

  describe "#avg" do

    context "when provided a single field" do

      context "when there are matching documents" do

        context "when the types are integers" do

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
            expect(avg).to eq(750)
          end
        end

        context "when the types are floats" do

          let!(:depeche) do
            Band.create(name: "Depeche Mode", rating: 10)
          end

          let!(:tool) do
            Band.create(name: "Tool", rating: 5)
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
            context.avg(:rating)
          end

          it "returns the avg of the provided field" do
            expect(avg).to eq(7.5)
          end
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
          expect(avg).to be_nil
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
          expect(max).to eq(1000)
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
          expect(min).to eq(500)
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
          expect(sum).to eq(1500)
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
end
