require "spec_helper"

describe Mongoid::Persistence::RemoveAll do

  let(:document) do
    Patient.new(:title => "Mr")
  end

  let(:collection) do
    stub_everything.quacks_like(Mongoid::Collection.allocate)
  end

  let(:cursor) do
    stub.quacks_like(Mongoid::Cursor.allocate)
  end

  let(:selector) do
    { :field1 => { "$exists" => true } }
  end

  before do
    Patient.stubs(:_collection).returns(collection)
  end

  describe "#initialize" do

    let(:remove_all) do
      Mongoid::Persistence::RemoveAll.new(Patient, false, selector)
    end

    it "sets the collection" do
      remove_all.collection.should == document.collection
    end

    it "sets the options" do
      remove_all.options.should ==
        { :safe => Mongoid.persist_in_safe_mode }
    end

    it "sets the selector" do
      remove_all.selector.should == selector
    end
  end

  describe "#persist" do

    def root_delete_expectation
      lambda {
        collection.expects(:remove).with(selector, :safe => true).returns(true)
      }
    end

    def root_find_expectation
      lambda {
        collection.expects(:find).with(
          selector
        ).returns(cursor)
      }
    end

    let(:remove_all) do
      Mongoid::Persistence::RemoveAll.new(Patient, false, selector)
    end

    context "when the document is a root document" do

      it "remove_alls the document from the collection" do
        root_delete_expectation.call
        root_find_expectation.call
        cursor.expects(:count).returns(30)
        remove_all.persist
      end

      it "returns the count of documents removed" do
        root_delete_expectation.call
        root_find_expectation.call
        cursor.expects(:count).returns(30)
        remove_all.persist.should == 30
      end
    end
  end
end
