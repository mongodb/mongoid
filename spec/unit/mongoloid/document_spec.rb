require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

describe Mongoloid::Document do

  describe "#create" do

    before do
      @collection = mock
    end

    context "with no attributes" do

      it "creates a new saved document" do
        Person.expects(:collection).returns(@collection)
        @collection.expects(:save).with({})
        person = Person.create
        person.should_not be_nil
      end

    end

    context "with attributes" do

      it "creates a new saved document" do
        Person.expects(:collection).returns(@collection)
        @collection.expects(:save).with({:test => "test"})
        person = Person.create(:test => "test")
        person.should_not be_nil
      end

    end

  end

  describe "#destroy" do

    before do
      @collection = mock
    end

    context "when the Document is remove from the database" do

      it "returns nil" do
        Person.expects(:collection).returns(@collection)
        id = XGen::Mongo::ObjectID.new
        @collection.expects(:remove).with(:_id => id)
        person = Person.new(:_id => id)
        person.destroy.should be_nil
      end

    end

  end

  describe "#fields" do

    it "adds a reader for the fields defined" do
      Person.fields([:name])
      @person = Person.new(:name => "Test")
      @person.name.should == "Test"
    end

    it "adds a writer for the fields defined" do
      Person.fields([:name])
      @person = Person.new(:name => "Test")
      @person.name = "Testy"
      @person.name.should == "Testy"
    end

  end

  describe "#find" do

    before do
      @attributes = { :document_class => "Person" }
      @collection = mock
    end

    context "when finding first" do

      it "delegates to find_first" do
        Person.expects(:collection).returns(@collection)
        @collection.expects(:find_one).with(:test => "Test").returns(@attributes)
        Person.find(:first, :test => "Test")
      end

    end

    context "when finding all" do

      before do
        @cursor = mock
        @persons = []
        @collection = mock
        Person.expects(:collection).returns(@collection)
      end

      it "delegates to find_all" do
        @collection.expects(:find).with(:test => "Test").returns(@cursor)
        @cursor.expects(:collect).returns(@persons)
        Person.find(:all, :test => "Test")
      end

    end

  end

  describe "#find_first" do

    before do
      @attributes = { :document_class => "Person" }
      @collection = mock
    end

    context "when a selector is provided" do

      it "finds the first document from the collection and instantiates it" do
        Person.expects(:collection).returns(@collection)
        @collection.expects(:find_one).with(:test => "Test").returns(@attributes)
        Person.find_first(:test => "Test").attributes.should == @attributes
      end

    end

    context "when a selector is not provided" do

      it "finds the first document from the collection and instantiates it" do
        Person.expects(:collection).returns(@collection)
        @collection.expects(:find_one).with(nil).returns(@attributes)
        Person.find_first.attributes.should == @attributes
      end

    end

  end

  describe "#find_all" do

    before do
      @cursor = mock
      @persons = []
      @collection = mock
    end

    context "when a selector is provided" do

      it "finds from the collection and instantiate objects for each returned" do
        Person.expects(:collection).returns(@collection)
        @collection.expects(:find).with(:test => "Test").returns(@cursor)
        @cursor.expects(:collect).returns(@persons)
        Person.find_all(:test => "Test")
      end

    end

    context "when a selector is not provided" do

      it "finds from the collection and instantiate objects for each returned" do
        Person.expects(:collection).returns(@collection)
        @collection.expects(:find).with(nil).returns(@cursor)
        @cursor.expects(:collect).returns(@persons)
        Person.find_all
      end

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

    before do
      @collection = mock
      Person.expects(:collection).returns(@collection)
    end

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
      @collection = mock
      Person.expects(:collection).returns(@collection)
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

class Person < Mongoloid::Document
  fields :title
  has_many :addresses
  has_one :name
end

class Address < Mongoloid::Document
  fields \
    :street,
    :city,
    :state,
    :post_code
  belongs_to :person
end

class Name < Mongoloid::Document
  fields \
    :first_name,
    :last_name
  belongs_to :person
end
