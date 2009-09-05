require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

describe Mongoloid::Document do

  before do
    @collection = mock
    @database = stub(:collection => @collection)
    Mongoloid.stubs(:database).returns(@database)
  end

  after do
    Person.instance_variable_set(:@collection, nil)
  end

  describe "#belongs_to" do

    it "adds a new Association to the collection" do
      address = Address.new
      address.associations[:person].should_not be_nil
    end

    it "creates a reader for the association" do
      address = Address.new
      address.should respond_to(:person)
    end

    it "creates a writer for the association" do
      address = Address.new
      address.should respond_to(:person=)
    end

  end

  describe "#collection" do

    it "sets the collection name to the class pluralized" do
      @database.expects(:collection).with("people").returns(@collection)
      Person.collection
    end

  end

  describe "#create" do

    context "with no attributes" do

      it "creates a new saved document" do
        @collection.expects(:save).with({})
        person = Person.create
        person.should_not be_nil
      end

    end

    context "with attributes" do

      it "creates a new saved document" do
        @collection.expects(:save).with({:test => "test"})
        person = Person.create(:test => "test")
        person.should_not be_nil
      end

    end

  end

  describe "#destroy" do

    context "when the Document is remove from the database" do

      it "returns nil" do
        id = XGen::Mongo::ObjectID.new
        @collection.expects(:remove).with(:_id => id)
        person = Person.new(:_id => id)
        person.destroy.should be_nil
      end

    end

  end

  describe "#fields" do

    before do
      Person.fields([:testing])
    end

    it "adds a reader for the fields defined" do
      @person = Person.new(:testing => "Test")
      @person.testing.should == "Test"
    end

    it "adds a writer for the fields defined" do
      @person = Person.new(:testing => "Test")
      @person.testing = "Testy"
      @person.testing.should == "Testy"
    end

  end

  describe "#find" do

    before do
      @attributes = { :document_class => "Person" }
    end

    context "when finding first" do

      it "delegates to find_first" do
        @collection.expects(:find_one).with(:test => "Test").returns(@attributes)
        Person.find(:first, :test => "Test")
      end

    end

    context "when finding all" do

      before do
        @cursor = mock
        @people = []
      end

      it "delegates to find_all" do
        @collection.expects(:find).with(:test => "Test").returns(@cursor)
        @cursor.expects(:collect).returns(@people)
        Person.find(:all, :test => "Test")
      end

    end

  end

  describe "#find_first" do

    before do
      @attributes = { :document_class => "Person" }
    end

    context "when a selector is provided" do

      it "finds the first document from the collection and instantiates it" do
        @collection.expects(:find_one).with(:test => "Test").returns(@attributes)
        Person.find_first(:test => "Test").attributes.should == @attributes
      end

    end

    context "when a selector is not provided" do

      it "finds the first document from the collection and instantiates it" do
        @collection.expects(:find_one).with(nil).returns(@attributes)
        Person.find_first.attributes.should == @attributes
      end

    end

  end

  describe "#find_all" do

    before do
      @cursor = mock
      @people = []
    end

    context "when a selector is provided" do

      it "finds from the collection and instantiate objects for each returned" do
        @collection.expects(:find).with(:test => "Test").returns(@cursor)
        @cursor.expects(:collect).returns(@people)
        Person.find_all(:test => "Test")
      end

    end

    context "when a selector is not provided" do

      it "finds from the collection and instantiate objects for each returned" do
        @collection.expects(:find).with(nil).returns(@cursor)
        @cursor.expects(:collect).returns(@people)
        Person.find_all
      end

    end

  end

  describe "#has_many" do

    it "adds a new Association to the collection" do
      person = Person.new
      person.associations[:addresses].should_not be_nil
    end

    it "creates a reader for the association" do
      person = Person.new
      person.should respond_to(:addresses)
    end

    it "creates a writer for the association" do
      person = Person.new
      person.should respond_to(:addresses=)
    end

  end

  describe "#has_one" do

    it "adds a new Association to the collection" do
      person = Person.new
      person.associations[:name].should_not be_nil
    end

    it "creates a reader for the association" do
      person = Person.new
      person.should respond_to(:name)
    end

    it "creates a writer for the association" do
      person = Person.new
      person.should respond_to(:name=)
    end

  end

  describe "#new" do

    context "with no attributes" do

      it "does not set any attributes" do
        person = Person.new
        person.attributes.empty?.should be_true
      end

    end

    context "with attributes" do

      before do
        @attributes = { :test => "test" }
      end

      it "sets the arributes hash on the object" do
        person = Person.new(@attributes)
        person.attributes.should == @attributes
      end

    end

  end

  describe "#new_record?" do

    context "when the object has been saved" do

      before do
        @person = Person.new(:_id => "1")
      end

      it "returns false" do
        @person.new_record?.should be_false
      end

    end

    context "when the object has not been saved" do

      before do
        @person = Person.new
      end

      it "returns true" do
        @person.new_record?.should be_true
      end

    end

  end

  describe "#paginate" do

    context "when pagination parameters are passed" do

      it "delegates offset and limit to find_all" do
        @collection.expects(:find).with({ :test => "Test" }, {:limit => 20, :offset => 20}).returns([])
        Person.paginate({ :test => "Test" }, { :page => 2, :per_page => 20 })
      end

    end

    context "when pagination parameters are not passed" do

      it "passes the default offset and limit to find_all" do
        @collection.expects(:find).with({ :test => "Test" }, {:limit => 20, :offset => 0}).returns([])
        Person.paginate({ :test => "Test" })
      end

    end

  end

  describe "#save" do

    before do
      @attributes = { :test => "test" }
      @person = Person.new(@attributes)
    end

    it "persists the object to the MongoDB collection" do
      @collection.expects(:save).with(@person.attributes)
      @person.save.should be_true
    end

  end

  describe "#update_attributes" do

    context "when attributes are provided" do

      it "saves and returns true" do
        person = Person.new
        person.expects(:save).returns(true)
        person.update_attributes(:test => "Test").should be_true
      end

    end

  end

end
