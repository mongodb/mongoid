# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Timestamps::Updated do

  describe ".included" do

    let(:agent) do
      Agent.new
    end

    let(:fields) do
      Agent.fields
    end

    before do
      agent.run_callbacks(:create)
      agent.run_callbacks(:save)
    end

    it "does not add created_at to the document" do
      expect(fields["created_at"]).to be_nil
    end

    it "adds updated_at to the document" do
      expect(fields["updated_at"]).to_not be_nil
    end

    it "forces the updated_at timestamps to UTC" do
      expect(agent.updated_at).to be_within(10).of(Time.now.utc)
    end
  end

  context "when the document is new" do

    context "when providing the timestamp" do

      let(:time) do
        Time.new(2012, 1, 1)
      end

      let(:doc) do
        Dokument.create!(updated_at: time)
      end

      it "does not override it with the default" do
        expect(doc.updated_at).to eq(time)
      end

      it "does not persist an auto value" do
        expect(doc.reload.updated_at).to eq(time)
      end
    end
  end

  context "when the document has not changed" do

    let(:agent) do
      Agent.instantiate("_id" => BSON::ObjectId.new, "account_ids" => [])
    end

    before do
      agent.new_record = false
    end

    it "does not run the update callbacks" do
      expect(agent).to receive(:updated_at=).never
      agent.save!
    end
  end

  context "when the document is created" do

    let(:agent) do
      Agent.create!
    end

    it "runs the update callbacks" do
      expect(agent.updated_at).to_not be_nil
      expect(agent.updated_at).to be_within(10).of(Time.now.utc)
    end
  end
end
