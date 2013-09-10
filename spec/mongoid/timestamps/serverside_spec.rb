require "spec_helper"

describe Mongoid::Timestamps::Serverside do
  shared_examples "ts" do
    let(:fields) { doc.fields }

    it "adds ts field to the document" do
      expect(fields["ts"]).to_not be_nil
    end

    it "should be first or second field in class to work properly (see https://jira.mongodb.org/browse/SERVER-1650)" do
      expect(fields.keys[0..1]).to include("ts")
    end
  end

  describe ".included" do
    let(:doc) { ServersideTimestampedDoc.new }

    before do
      doc.run_callbacks(:initialize)
      doc.run_callbacks(:save)
    end

    include_examples "ts"
  end

  describe "when document is created" do
    let(:doc) { ServersideTimestampedDoc.create }

    include_examples "ts"
  end
end
