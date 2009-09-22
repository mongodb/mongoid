require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

describe Mongoid::Document do

  before do
    @collection = mock
    @database = stub(:collection => @collection)
    Mongoid.stubs(:database).returns(@database)
  end

  after do
    Person.instance_variable_set(:@collection, nil)
  end

  describe "#belongs_to" do

    it "adds a new Association to the collection" do
      address = Address.new
      address.person.should_not be_nil
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
        id = Mongo::ObjectID.new
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

    context "when an id is passed in" do

      before do
        @id = Mongo::ObjectID.new
      end

      it "delegates to find_first" do
        @collection.expects(:find_one).with(Mongo::ObjectID.from_string(@id.to_s)).returns(@attributes)
        Person.find(@id.to_s)
      end

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

  describe "#group_by" do

    before do
      @reduce = "function(obj, prev) { prev.group.push(obj); }"
    end

    it "returns documents grouped by the supplied fields" do
      results = [{ "title" => "Sir", "group" => [{ "title" => "Sir", "age" => 30 }] }]
      @collection.expects(:group).with([:title], {}, { :group => [] }, @reduce).returns(results)
      grouped = Person.group_by([:title], {})
      people = grouped.first["group"]
      people.first.should be_a_kind_of(Person)
    end

  end

  describe "#has_many" do

    it "adds a new Association to the collection" do
      person = Person.new
      person.addresses.should_not be_nil
    end

    it "creates a reader for the association" do
      person = Person.new
      person.should respond_to(:addresses)
    end

    it "creates a writer for the association" do
      person = Person.new
      person.should respond_to(:addresses=)
    end

    context "when setting the association directly" do

      before do
        @attributes = { :title => "Sir",
          :addresses => [
            { :street => "Street 1", :document_class => "Address" },
            { :street => "Street 2", :document_class => "Address" } ] }
        @person = Person.new(@attributes)
      end

      it "sets the attributes for the association" do
        address = Address.new(:street => "New Street", :document_class => "Address")
        @person.addresses = [address]
        @person.addresses.first.street.should == "New Street"
      end

    end

  end

  describe "#has_one" do

    it "adds a new Association to the collection" do
      person = Person.new
      person.name.should_not be_nil
    end

    it "creates a reader for the association" do
      person = Person.new
      person.should respond_to(:name)
    end

    it "creates a writer for the association" do
      person = Person.new
      person.should respond_to(:name=)
    end

    context "when setting the association directly" do

      before do
        @attributes = { :title => "Sir",
          :name => { :first_name => "Test" } }
        @person = Person.new(@attributes)
      end

      it "sets the attributes for the association" do
        name = Name.new(:first_name => "New Name", :document_class => "Name")
        @person.name = name
        @person.name.first_name.should == "New Name"
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

  describe "#parent" do

    before do
      @attributes = { :title => "Sir",
        :addresses => [
          { :street => "Street 1", :document_class => "Address" },
          { :street => "Street 2", :document_class => "Address" } ] }
      @person = Person.new(@attributes)
    end

    context "when document is embedded" do

      it "returns the parent document" do
        @person.addresses.first.parent.should == @person
      end

    end

    context "when document is root" do

      it "returns nil" do
        @person.parent.should be_nil
      end

    end

  end

  describe "#save" do

    context "when the document is the root" do

      before do
        @attributes = { :test => "test" }
        @person = Person.new(@attributes)
      end

      it "persists the object to the MongoDB collection" do
        @collection.expects(:save).with(@person.attributes)
        @person.save.should be_true
      end

    end

    context "when the document is embedded" do

      before do
        @attributes = { :title => "Sir",
          :addresses => [
            { :street => "Street 1", :document_class => "Address" },
            { :street => "Street 2", :document_class => "Address" } ] }
        @person = Person.new(@attributes)
      end

      it "saves the root document" do
        @collection.expects(:save).with(@person.attributes)
        @person.addresses.first.save
      end

    end

  end

  describe "#to_param" do

    it "returns the id" do
      id = Mongo::ObjectID.new
      Person.new(:_id => id).to_param.should == id.to_s
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

  context "validations" do

    after do
      Person.validations.clear
    end

    describe "#validates_acceptance_of" do

      it "adds the acceptance validation" do
        Person.class_eval do
          validates_acceptance_of :terms
        end
        Person.validations.first.should be_a_kind_of(Validatable::ValidatesAcceptanceOf)
      end

    end

    describe "#validates_associated" do

      it "adds the associated validation" do
        Person.class_eval do
          validates_associated :name
        end
        Person.validations.first.should be_a_kind_of(Validatable::ValidatesAssociated)
      end

    end

    describe "#validates_format_of" do

      it "adds the format validation" do
        Person.class_eval do
          validates_format_of :title, :with => /[A-Za-z]/
        end
        Person.validations.first.should be_a_kind_of(Validatable::ValidatesFormatOf)
      end

    end

    describe "#validates_length_of" do

      it "adds the length validation" do
        Person.class_eval do
          validates_length_of :title, :minimum => 10
        end
        Person.validations.first.should be_a_kind_of(Validatable::ValidatesLengthOf)
      end

    end

    describe "#validates_numericality_of" do

      it "adds the numericality validation" do
        Person.class_eval do
          validates_numericality_of :age
        end
        Person.validations.first.should be_a_kind_of(Validatable::ValidatesNumericalityOf)
      end

    end

    describe "#validates_presence_of" do

      it "adds the presence validation" do
        Person.class_eval do
          validates_presence_of :title
        end
        Person.validations.first.should be_a_kind_of(Validatable::ValidatesPresenceOf)
      end

    end

    describe "#validates_true_for" do

      it "adds the true validation" do
        Person.class_eval do
          validates_true_for :title, :logic => lambda { title == "Esquire" }
        end
        Person.validations.first.should be_a_kind_of(Validatable::ValidatesTrueFor)
      end

    end

  end


end
