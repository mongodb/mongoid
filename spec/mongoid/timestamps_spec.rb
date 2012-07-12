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
      fields["created_at"].should_not be_nil
    end

    it "adds updated_at to the document" do
      fields["updated_at"].should_not be_nil
    end

    it "forces the created_at timestamps to UTC" do
      document.created_at.should be_within(10).of(Time.now.utc)
    end

    it "forces the updated_at timestamps to UTC" do
      document.updated_at.should be_within(10).of(Time.now.utc)
    end

    it "ensures created_at equals updated_at on new records" do
      document.updated_at.should eq(document.created_at)
    end

    it "includes a record_timestamps class_accessor to ease AR compatibility" do
      Dokument.should.respond_to? :record_timestamps
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
      document.should_receive(:updated_at=).never
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
      document.should_receive(:updated_at=).never
      document.save
    end
  end

  context "when the document is created" do

    let!(:document) do
      Dokument.create
    end

    it "runs the update callbacks" do
      document.updated_at.should eq(document.created_at)
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
      document.updated_at.should be_within(1).of(Time.now)
    end
  end
end
