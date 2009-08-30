require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

class Document < Mongoloid::Document
end

describe Mongoloid::Document do

  before do
    @collection = mock
    Document.expects(:collection).returns(@collection)
  end

  describe "#collection" do

    before do
      @database = mock
    end

    it "should get the collection with class name from the database" do
      Mongoloid.expects(:database).returns(@database)
      @database.expects(:collection).with("document").returns(@collection)
      Document.collection.should == @collection
    end

  end

  describe "#create" do

    context "with no attributes" do

      it "creates a new saved document" do
        @collection.expects(:save).with({})
        document = Document.create
        document.should_not be_nil
      end

    end

    context "with attributes" do

      it "creates a new saved document" do
        @collection.expects(:save).with({:test => "test"})
        document = Document.create(:test => "test")
        document.should_not be_nil
      end

    end

  end

  describe "#destroy" do

    context "when the Document is remove from the database" do

      it "returns nil" do
        id = XGen::Mongo::ObjectID.new
        @collection.expects(:remove).with(:_id => id)
        document = Document.new(:_id => id)
        document.destroy.should be_nil
      end

    end

  end

  describe "#find" do

    context "when finding first" do

      it "delegates to find_first" do
        @collection.expects(:find_one).with(:test => "Test").returns(@attributes)
        Document.find(:first, :test => "Test")
      end

    end

    context "when finding all" do
      
      before do
        @cursor = mock
        @documents = []
      end

      it "delegates to find_all" do
        @collection.expects(:find).with(:test => "Test").returns(@cursor)
        @cursor.expects(:collect).returns(@documents)
        Document.find(:all, :test => "Test")
      end

    end

  end

  describe "#find_first" do

    before do
      @attributes = {}
    end

    context "when a selector is provided" do
      
      it "finds the first document from the collection and instantiates it" do
        @collection.expects(:find_one).with(:test => "Test").returns(@attributes)
        Document.find_first(:test => "Test").attributes.should == @attributes
      end

    end

    context "when a selector is not provided" do

      it "finds the first document from the collection and instantiates it" do
        @collection.expects(:find_one).with(nil).returns(@attribute)
        Document.find_first.attributes.should == @attributes
      end

    end

  end

  describe "#find_all" do

    before do
      @cursor = mock
      @documents = []
    end

    context "when a selector is provided" do
      
      it "finds from the collection and instantiate objects for each returned" do
        @collection.expects(:find).with(:test => "Test").returns(@cursor)
        @cursor.expects(:collect).returns(@documents)
        Document.find_all(:test => "Test")
      end

    end

    context "when a selector is not provided" do

      it "finds from the collection and instantiate objects for each returned" do
        @collection.expects(:find).with(nil).returns(@cursor)
        @cursor.expects(:collect).returns(@documents)
        Document.find_all
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

  describe "#paginate" do

    context "when pagination parameters are passed" do

      it "delegates offset and limit to find_all" do
        @collection.expects(:find).with({ :test => "Test" }, {:limit => 20, :offset => 20}).returns([])
        Document.paginate({ :test => "Test" }, { :page => 2, :per_page => 20 })
      end

    end

    context "when pagination parameters are not passed" do

      it "passes the default offset and limit to find_all" do
        @collection.expects(:find).with({ :test => "Test" }, {:limit => 20, :offset => 0}).returns([])
        Document.paginate({ :test => "Test" })
      end

    end

  end

  describe "#save" do

    before do
      @attributes = { :test => "test" }
      @document = Document.new(@attributes)
    end

    it "persists the object to the MongoDB collection" do
      @collection.expects(:save).with(@document.attributes)
      @document.save.should be_true
    end

  end

  describe "#update_attributes" do

    context "when attributes are provided" do

      it "saves and returns true" do
        document = Document.new
        document.expects(:save).returns(true)
        document.update_attributes(:test => "Test").should be_true
      end

    end

  end

end
