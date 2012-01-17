require "spec_helper"

describe Mongoid::Relations::Referenced::Batch::Insert do

  describe "#consume" do

    let(:insert) do
      described_class.new
    end

    let(:document) do
      { :field => "value" }
    end

    let(:options) do
      { :safe => true }
    end

    before do
      insert.consume(document, options)
    end

    it "sets consumed to true" do
      insert.should be_consumed
    end

    it "sets the options" do
      insert.options.should == options
    end

    it "appends the document" do
      insert.documents.should == [ document ]
    end
  end

  describe "#consumed?" do

    context "when the operation has been consumed" do

      let(:insert) do
        described_class.new
      end

      before do
        insert.consume({})
      end

      it "returns true" do
        insert.should be_consumed
      end
    end

    context "when the operation has not been consumed" do

      let(:insert) do
        described_class.new
      end

      it "returns false" do
        insert.should_not be_consumed
      end
    end
  end

  describe "#execute" do

    let(:insert) do
      described_class.new
    end

    let(:collection) do
      stub
    end

    context "when the operation has been consumed" do

      before do
        insert.consume({})
      end

      it "sends the insert to the collection" do
        collection.expects(:insert).with([{}], {})
        insert.execute(collection)
      end
    end

    context "when the operation has not been comsumed" do

      it "does not send an insert" do
        collection.expects(:insert).never
        insert.execute(collection)
      end
    end
  end
end
