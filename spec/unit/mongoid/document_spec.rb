require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

describe Mongoid::Document do

  before do
    @collection = stub(:name => "people")
    @database = stub(:collection => @collection)
    Mongoid.stubs(:database).returns(@database)
  end

  after do
    Person.instance_variable_set(:@collection, nil)
    @database = nil
    @collection = nil
  end

  describe "#aggregate" do

    before do
      @reduce = "function(obj, prev) { prev.count++; }"
    end

    it "returns documents grouped by the supplied fields" do
      results = [{ "title" => "Sir", "count" => 30 }]
      @collection.expects(:group).with([:title], nil, {:count => 0}, @reduce).returns(results)
      grouped = Person.aggregate([:title], {})
      grouped.first["count"].should == 30
    end

  end

  describe "#all" do

    before do
      @cursor = mock
      @people = []
    end

    context "when a selector is provided" do

      it "finds from the collection and instantiate objects for each returned" do
        @collection.expects(:find).with({ :test => "Test" }, {}).returns(@cursor)
        @cursor.expects(:collect).returns(@people)
        Person.all(:conditions => {:test => "Test"})
      end

    end

    context "when a selector is not provided" do

      it "finds from the collection and instantiate objects for each returned" do
        @collection.expects(:find).with(nil, {}).returns(@cursor)
        @cursor.expects(:collect).returns(@people)
        Person.all
      end

    end

  end

  describe "#association=" do

    before do
      @name = Name.new
      @person = Person.new
    end

    it "parentizes the association" do
      @person.name = @name
      @name.parent.should == @person
    end

  end

  describe "#belongs_to" do

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

    before do
      @person = Person.new
    end

    it "sets the collection name to the class pluralized" do
      Person.collection.name.should == "people"
    end

    context "when document is embedded" do

      before do
        @address = Address.new
      end

      it "returns nil" do
        Address.collection.should be_nil
      end

    end

  end

  describe "#field" do

    context "with no options" do

      before do
        Person.field(:testing)
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

  end

  describe "#find" do

    before do
      @attributes = {}
      @criteria = mock
    end

    context "when an id is passed in" do

      before do
        @id = Mongo::ObjectID.new
      end

      it "delegates to criteria" do
        Mongoid::Criteria.expects(:translate).with(@id.to_s).returns(@criteria)
        @criteria.expects(:execute).with(Person).returns(@attributes)
        Person.find(@id.to_s)
      end

    end

    context "when finding first" do

      it "delegates to criteria" do
        Mongoid::Criteria.expects(:translate).with(:first, :conditions => { :test => "Test" }).returns(@criteria)
        @criteria.expects(:execute).with(Person).returns(@attributes)
        Person.find(:first, :conditions => { :test => "Test" })
      end

    end

    context "when finding all" do

      before do
        @cursor = mock
        @people = []
      end

      it "delegates to find_all" do
        @collection.expects(:find).with({:test => "Test"}, {}).returns(@cursor)
        @cursor.expects(:collect).returns(@people)
        Person.find(:all, :conditions => { :test => "Test" })
      end

    end

    context "when sorting" do

      before do
        @cursor = mock
        @people = []
      end

      it "adds the sort parameters for the collection call" do
        @collection.expects(:find).with({ :test => "Test" }, { :sort => { :test => -1 }}).returns(@cursor)
        @cursor.expects(:collect).returns(@people)
        Person.find(:all, :conditions => { :test => "Test" }, :sort => { :test => -1 })
      end
    end

  end

  describe "#first" do

    before do
      @attributes = {}
    end

    context "when a selector is provided" do

      it "finds the first document from the collection and instantiates it" do
        @collection.expects(:find_one).with({ :test => "Test" }, {}).returns(@attributes)
        Person.first(:conditions => {:test => "Test"}).attributes.should == @attributes
      end

    end

    context "when a selector is not provided" do

      it "finds the first document from the collection and instantiates it" do
        @collection.expects(:find_one).with(nil, {}).returns(@attributes)
        Person.first.attributes.should == @attributes
      end

    end

  end

  describe "#group_by" do

    before do
      @reduce = "function(obj, prev) { prev.group.push(obj); }"
    end

    it "returns documents grouped by the supplied fields" do
      results = [{ "title" => "Sir", "group" => [{ "title" => "Sir", "age" => 30 }] }]
      @collection.expects(:group).with([:title], nil, { :group => [] }, @reduce).returns(results)
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
            { :street => "Street 1" },
            { :street => "Street 2" } ] }
        @person = Person.new(@attributes)
      end

      it "sets the attributes for the association" do
        address = Address.new(:street => "New Street")
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
        name = Name.new(:first_name => "New Name")
        @person.name = name
        @person.name.first_name.should == "New Name"
      end

    end

  end

  describe "#has_timestamps" do

    before do
      @tester = Tester.new
    end

    it "adds created_on and last_modified to the document" do
      fields = Tester.instance_variable_get(:@fields)
      fields[:created_at].should_not be_nil
      fields[:last_modified].should_not be_nil
    end

  end

  describe "#index" do

    context "when unique options are not provided" do

      it "delegates to collection with unique => false" do
        @collection.expects(:create_index).with(:title, :unique => false)
        Person.index :title
      end

    end

    context "when unique option is provided" do

      it "delegates to collection with unique option" do
        @collection.expects(:create_index).with(:title, :unique => true)
        Person.index :title, :unique => true
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
      @cursor = stub(:count => 100, :collect => [])
    end

    context "when pagination parameters are passed" do

      it "delegates to will paginate with the results" do
        @collection.expects(:find).with({ :test => "Test" }, { :sort => nil, :limit => 20, :skip => 20}).returns(@cursor)
        Person.paginate(:conditions => { :test => "Test" }, :page => 2, :per_page => 20)
      end

    end

    context "when pagination parameters are not passed" do

      it "delegates to will paginate with default values" do
        @collection.expects(:find).with({ :test => "Test" }, { :sort => nil, :limit => 20, :skip => 0}).returns(@cursor)
        Person.paginate(:conditions => { :test => "Test" })
      end

    end

    context "when sorting paramters provided" do

      it "adds the sorting parameters in the collection#find" do
        @collection.expects(:find).with({ :test => "Test" }, { :sort => { :test => -1}, :limit => 20, :skip => 0}).returns(@cursor)
        Person.paginate(:conditions => { :test => "Test" }, :sort => { :test => -1 })
      end

    end

  end

  describe "#parent" do

    before do
      @attributes = { :title => "Sir",
        :addresses => [
          { :street => "Street 1" },
          { :street => "Street 2" } ] }
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

  describe "#read_attribute" do

    context "when attribute does not exist" do

      before do
        Person.field :weight, :default => 100
        @person = Person.new
      end

      it "returns the default value" do
        @person.weight.should == 100
      end

    end

  end

  describe "#to_param" do

    it "returns the id" do
      id = Mongo::ObjectID.new
      Person.new(:_id => id).to_param.should == id.to_s
    end

  end

  describe "#write_attribute" do

    context "when attribute does not exist" do

      before do
        Person.field :weight, :default => 100
        @person = Person.new
      end

      it "returns the default value" do
        @person.weight = nil
        @person.weight.should == 100
      end

    end

  end

  context "validations" do

    context "when defining using macros" do

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

    context "when running validations" do

      before do
        @person = Person.new
      end

      after do
        Person.validations.clear
      end

      describe "#validates_acceptance_of" do

        it "fails if field not accepted" do
          Person.class_eval do
            validates_acceptance_of :terms
          end
          @person.valid?.should be_false
          @person.errors.on(:terms).should_not be_nil
        end

      end

      describe "#validates_associated" do

        context "when association is a has_many" do

          it "fails when any association fails validation"

        end

        context "when association is a has_one" do

          it "fails when the association fails validation" do
            Person.class_eval do
              validates_associated :name
            end
            Name.class_eval do
              validates_presence_of :first_name
            end
            @person.name = Name.new
            @person.valid?.should be_false
            @person.errors.on(:name).should_not be_nil
          end

        end

      end

      describe "#validates_format_of" do

        it "fails if the field is in the wrong format" do
          Person.class_eval do
            validates_format_of :title, :with => /[A-Za-z]/
          end
          @person.title = 10
          @person.valid?.should be_false
          @person.errors.on(:title).should_not be_nil
        end

      end

      describe "#validates_length_of" do

        it "fails if the field is the wrong length" do
          Person.class_eval do
            validates_length_of :title, :minimum => 10
          end
          @person.title = "Testing"
          @person.valid?.should be_false
          @person.errors.on(:title).should_not be_nil
        end

      end

      describe "#validates_numericality_of" do

        it "fails if the field is not a number" do
          Person.class_eval do
            validates_numericality_of :age
          end
          @person.age = "foo"
          @person.valid?.should be_false
          @person.errors.on(:age).should_not be_nil
        end

      end

      describe "#validates_presence_of" do

        it "fails if the field is nil" do
          Person.class_eval do
            validates_presence_of :title
          end
          @person.valid?.should be_false
          @person.errors.on(:title).should_not be_nil
        end

      end

      describe "#validates_true_for" do

        it "fails if the logic returns false" do
          Person.class_eval do
            validates_true_for :title, :logic => lambda { title == "Esquire" }
          end
          @person.valid?.should be_false
          @person.errors.on(:title).should_not be_nil
        end

      end

    end

  end

end
