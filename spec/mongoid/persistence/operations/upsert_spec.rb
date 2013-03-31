require "spec_helper"

describe Mongoid::Persistence::Operations::Upsert do

  describe "#persist" do

    context "when the document is new" do

      let(:band) do
        Band.new
      end

      let(:upsert) do
        described_class.new(band)
      end

      let!(:persisted) do
        upsert.persist
      end

      it "inserts the document in the database" do
        expect(band.reload).to eq(band)
      end

      it "returns true" do
        expect(persisted).to be_true
      end

      it "runs the upsert callbacks" do
        expect(band.upserted).to be_true
      end
    end

    context "when the document is not new" do

      let(:band) do
        Band.create.tap do |b|
          b.name = "Tool"
        end
      end

      let(:upsert) do
        described_class.new(band)
      end

      let!(:persisted) do
        upsert.persist
      end

      it "updates the document in the database" do
        expect(band.reload.name).to eq("Tool")
      end

      it "returns true" do
        expect(persisted).to be_true
      end
    end
  end
end
