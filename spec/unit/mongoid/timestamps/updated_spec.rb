require "spec_helper"

describe Mongoid::Timestamps::Updated do

  describe ".included" do

    let(:game) do
      Game.new
    end

    let(:fields) do
      Game.fields
    end

    before do
      game.run_callbacks(:create)
      game.run_callbacks(:save)
    end

    it "does not add created_at to the document" do
      fields["created_at"].should be_nil
    end

    it "adds updated_at to the document" do
      fields["updated_at"].should_not be_nil
    end

    it "forces the updated_at timestamps to UTC" do
      game.updated_at.should be_within(10).of(Time.now.utc)
    end

    it "includes a record_timestamps class_accessor to ease AR compatibility" do
      Game.should.respond_to? :record_timestamps
    end
  end

  context "when the document has not changed" do

    let(:game) do
      Game.new(:created_at => Time.now.utc)
    end

    before do
      game.new_record = false
    end

    it "does not run the update callbacks" do
      game.expects(:updated_at=).never
      game.save
    end
  end

  context "when the document is created" do

    let(:game) do
      Game.create
    end

    it "runs the update callbacks" do
      game.updated_at.should_not be_nil
      game.updated_at.should be_within(10).of(Time.now.utc)
    end
  end
end
