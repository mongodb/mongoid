require "spec_helper"

describe Mongoid::Timestamps do

  describe ".included" do

    let(:document) do
      Dokument.new
    end

    let(:fields) do
      Dokument.fields
    end

    before do
      document.run_callbacks(:create)
      document.run_callbacks(:save)
    end

    it "adds created_at to the document" do
      expect(fields["created_at"]).to_not be_nil
    end

    it "adds updated_at to the document" do
      expect(fields["updated_at"]).to_not be_nil
    end

    it "forces the created_at timestamps to UTC" do
      expect(document.created_at).to be_within(10).of(Time.now.utc)
    end

    it "forces the updated_at timestamps to UTC" do
      expect(document.updated_at).to be_within(10).of(Time.now.utc)
    end

    it "ensures created_at equals updated_at on new records" do
      expect(document.updated_at).to eq(document.created_at)
    end
  end

  context "when the document has not changed" do

    let(:document) do
      Dokument.instantiate(Dokument.new.attributes)
    end

    before do
      document.new_record = false
    end

    it "does not run the update callbacks" do
      expect(document).to receive(:updated_at=).never
      document.save
    end
  end

  context "when the document has changed with updated_at specified" do

    let(:document) do
      Dokument.new(created_at: Time.now.utc)
    end

    before do
      document.new_record = false
      document.updated_at = DateTime.parse("2001-06-12")
    end

    it "does not set updated at" do
      expect(document).to receive(:updated_at=).never
      document.save
    end
  end

  context "when the document is created" do

    let!(:document) do
      Dokument.create
    end

    it "runs the update callbacks" do
      expect(document.updated_at).to eq(document.created_at)
    end
  end

  context "when only embedded documents have changed" do

    let!(:document) do
      Dokument.create(updated_at: 2.days.ago)
    end

    let!(:address) do
      document.addresses.create(street: "Karl Marx Strasse")
    end

    let!(:updated_at) do
      document.updated_at
    end

    before do
      address.number = 1
      document.save
    end

    it "updates the root document updated at" do
      expect(document.updated_at).to be_within(1).of(Time.now)
    end
  end
end
