require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

class Document < Mongoloid::Document
end

describe Mongoloid::Document do

  before do
    @collection = mock
    Document.expects(:collection).returns(@collection)
  end

  describe "#create" do

    context "with no attributes" do

      it "should create a new saved document" do
        @collection.expects(:save).with({})
        document = Document.create
        document.should_not be_nil
      end

    end

    context "with attributes" do

      it "should create a new saved document" do
        @collection.expects(:save).with({:test => "test"})
        document = Document.create(:test => "test")
        document.should_not be_nil
      end

    end

  end
  
  describe "#find" do

    before do
      @cursor = mock
      @documents = []
    end

    context "when a selector is provided" do
      
      it "should find from the collection and instantiate objects for each returned" do
        @collection.expects(:find).with(:test => "Test").returns(@cursor)
        @cursor.expects(:collect).returns(@documents)
        Document.find(:test => "Test")
      end

    end

    context "when a selector is not provided" do

      it "should find from the collection and instantiate objects for each returned" do
        @collection.expects(:find).with(nil).returns(@cursor)
        @cursor.expects(:collect).returns(@documents)
        Document.find
      end

    end

  end

  describe "#new" do

    context "with no attributes" do

      it "does not set any attributes" do
        document = Document.new
        document.attributes.empty?.should be_true
      end

    end

    context "with attributes" do

      before do
        @attributes = { :test => "test" }
      end

      it "sets the arributes hash on the object" do
        document = Document.new(@attributes)
        document.attributes.should == @attributes
      end

    end

  end

  describe "#new_record?" do

    context "when the object has been saved" do

      before do
        @document = Document.new(:_id => "1")
      end

      it "returns false" do
        @document.new_record?.should be_false
      end
    end

    context "when the object has not been saved" do

      before do
        @document = Document.new
      end

      it "returns true" do
        @document.new_record?.should be_true
      end
    end

  end

  describe "#save" do

    before do
      @attributes = { :test => "test" }
      @document = Document.new(@attributes)
    end

    it "should persist the object to the MongoDB collection" do
      @collection.expects(:save).with(@document.attributes)
      @document.save
    end

  end

end
