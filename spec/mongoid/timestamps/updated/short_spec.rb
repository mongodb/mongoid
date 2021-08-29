# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Timestamps::Updated::Short do

  describe ".included" do

    let(:agent) do
      ShortAgent.new
    end

    let(:fields) do
      ShortAgent.fields
    end

    before do
      agent.run_callbacks(:create)
      agent.run_callbacks(:save)
    end

    it "does not add c_at to the document" do
      expect(fields["c_at"]).to be_nil
    end

    it "adds u_at to the document" do
      expect(fields["u_at"]).to_not be_nil
    end

    it "does not add the long updated_at" do
      expect(fields["updated_at"]).to be_nil
    end

    it "forces the updated_at timestamps to UTC" do
      expect(agent.updated_at).to be_within(10).of(Time.now.utc)
    end

    it "aliases the raw field" do
      expect(agent.u_at).to eq(agent.updated_at)
    end
  end

  context "when the document is new" do

    context "when providing the timestamp" do

      let(:time) do
        Time.new(2012, 1, 1)
      end

      let(:doc) do
        ShortAgent.create!(updated_at: time)
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
      ShortAgent.instantiate("_id" => BSON::ObjectId.new, "account_ids" => [])
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
      ShortAgent.create!
    end

    it "runs the update callbacks" do
      expect(agent.updated_at).to_not be_nil
      expect(agent.updated_at).to be_within(10).of(Time.now.utc)
    end
  end
end
