require "spec_helper"

describe Mongoid::Persistence::Operations::Remove do

  let(:document) do
    Patient.new(:title => "Mr")
  end

  let(:address) do
    Address.new(:street => "Oxford St")
  end

  let(:collection) do
    stub.quacks_like(Mongoid::Collection.allocate)
  end

  before do
    document.stubs(:collection).returns(collection)
  end

  describe "#initialize" do

    let(:remove) do
      described_class.new(document)
    end

    it "sets the document" do
      remove.document.should == document
    end

    it "sets the collection" do
      remove.collection.should == document.collection
    end

    it "defaults validation to true" do
      remove.should be_validating
    end

    it "sets the options" do
      remove.options.should ==
        { :safe => Mongoid.persist_in_safe_mode }
    end
  end

  describe "#persist" do

    def root_delete_expectation
      lambda {
        collection.expects(:remove).with(
          { :_id => document.id },
          :safe => false
        ).returns(true)
      }
    end

    let(:remove) do
      described_class.new(document)
    end

    context "when the document is a root document" do

      it "removes the document from the collection" do
        root_delete_expectation.call
        remove.persist.should == true
      end
    end
  end
end
