require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

class Parent < Mongoloid::Document
end
class Child < Mongoloid::Document
end

describe Mongoloid::Document do

  describe "#belongs_to" do

    it "adds the new Association" do
      Child.belongs_to :parent
      Child.associations[:parent].type.should == :belongs_to
    end

  end

  describe "#collection" do

    before do
      @database = mock
      @collection = mock
      Parent.expects(:collection).returns(@collection)
    end

    it "should get the collection with class name from the database" do
      Mongoloid.expects(:database).returns(@database)
      @database.expects(:collection).with("parent").returns(@collection)
      Parent.collection.should == @collection
    end

  end

  describe "#create" do

    before do
      @collection = mock
      Parent.expects(:collection).returns(@collection)
    end

    context "with no attributes" do

      it "creates a new saved document" do
        @collection.expects(:save).with({})
        parent = Parent.create
        parent.should_not be_nil
      end

    end

    context "with attributes" do

      it "creates a new saved document" do
        @collection.expects(:save).with({:test => "test"})
        parent = Parent.create(:test => "test")
        parent.should_not be_nil
      end

    end

  end

  describe "#destroy" do

    before do
      @collection = mock
      Parent.expects(:collection).returns(@collection)
    end

    context "when the Document is remove from the database" do

      it "returns nil" do
        id = XGen::Mongo::ObjectID.new
        @collection.expects(:remove).with(:_id => id)
        parent = Parent.new(:_id => id)
        parent.destroy.should be_nil
      end

    end

  end

  describe "#fields" do

    it "adds a reader for the fields defined" do
      Parent.fields([:name])
      @parent = Parent.new(:name => "Test")
      @parent.name.should == "Test"
    end

    it "adds a writer for the fields defined" do
      Parent.fields([:name])
      @parent = Parent.new(:name => "Test")
      @parent.name = "Testy"
      @parent.name.should == "Testy"
    end

  end

  describe "#find" do

    before do
      @collection = mock
      Parent.expects(:collection).returns(@collection)
    end

    context "when finding first" do

      it "delegates to find_first" do
        @collection.expects(:find_one).with(:test => "Test").returns(@attributes)
        Parent.find(:first, :test => "Test")
      end

    end

    context "when finding all" do

      before do
        @cursor = mock
        @parents = []
        @collection = mock
        Parent.expects(:collection).returns(@collection)
      end

      it "delegates to find_all" do
        @collection.expects(:find).with(:test => "Test").returns(@cursor)
        @cursor.expects(:collect).returns(@parents)
        Parent.find(:all, :test => "Test")
      end

    end

  end

  describe "#find_first" do

    before do
      @attributes = {}
      @collection = mock
      Parent.expects(:collection).returns(@collection)
    end

    context "when a selector is provided" do

      it "finds the first document from the collection and instantiates it" do
        @collection.expects(:find_one).with(:test => "Test").returns(@attributes)
        Parent.find_first(:test => "Test").attributes.should == @attributes
      end

    end

    context "when a selector is not provided" do

      it "finds the first document from the collection and instantiates it" do
        @collection.expects(:find_one).with(nil).returns(@attribute)
        Parent.find_first.attributes.should == @attributes
      end

    end

  end

  describe "#find_all" do

    before do
      @cursor = mock
      @parents = []
      @collection = mock
      Parent.expects(:collection).returns(@collection)
    end

    context "when a selector is provided" do

      it "finds from the collection and instantiate objects for each returned" do
        @collection.expects(:find).with(:test => "Test").returns(@cursor)
        @cursor.expects(:collect).returns(@parents)
        Parent.find_all(:test => "Test")
      end

    end

    context "when a selector is not provided" do

      it "finds from the collection and instantiate objects for each returned" do
        @collection.expects(:find).with(nil).returns(@cursor)
        @cursor.expects(:collect).returns(@parents)
        Parent.find_all
      end

    end

  end

  describe "#has_many" do

    it "adds the new Association" do
      Parent.has_many :childs
      Parent.associations[:childs].type.should == :has_many
    end

  end

  describe "#new" do

    context "with no attributes" do

      it "does not set any attributes" do
        parent = Parent.new
        parent.attributes.empty?.should be_true
      end

    end

    context "with attributes" do

      before do
        @attributes = { :test => "test" }
      end

      it "sets the arributes hash on the object" do
        parent = Parent.new(@attributes)
        parent.attributes.should == @attributes
      end

    end

  end

  describe "#new_record?" do

    context "when the object has been saved" do

      before do
        @parent = Parent.new(:_id => "1")
      end

      it "returns false" do
        @parent.new_record?.should be_false
      end

    end

    context "when the object has not been saved" do

      before do
        @parent = Parent.new
      end

      it "returns true" do
        @parent.new_record?.should be_true
      end

    end

  end

  describe "#paginate" do

    before do
      @collection = mock
      Parent.expects(:collection).returns(@collection)
    end

    context "when pagination parameters are passed" do

      it "delegates offset and limit to find_all" do
        @collection.expects(:find).with({ :test => "Test" }, {:limit => 20, :offset => 20}).returns([])
        Parent.paginate({ :test => "Test" }, { :page => 2, :per_page => 20 })
      end

    end

    context "when pagination parameters are not passed" do

      it "passes the default offset and limit to find_all" do
        @collection.expects(:find).with({ :test => "Test" }, {:limit => 20, :offset => 0}).returns([])
        Parent.paginate({ :test => "Test" })
      end

    end

  end

  describe "#save" do

    before do
      @attributes = { :test => "test" }
      @parent = Parent.new(@attributes)
      @collection = mock
      Parent.expects(:collection).returns(@collection)
    end

    it "persists the object to the MongoDB collection" do
      @collection.expects(:save).with(@parent.attributes)
      @parent.save.should be_true
    end

  end

  describe "#update_attributes" do

    context "when attributes are provided" do

      it "saves and returns true" do
        parent = Parent.new
        parent.expects(:save).returns(true)
        parent.update_attributes(:test => "Test").should be_true
      end

    end

  end

end
