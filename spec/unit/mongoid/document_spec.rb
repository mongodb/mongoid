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

  describe "#key" do

    context "when key is single field" do

      before do
        Address.key :street
        @address = Address.new(:street => "Testing Street Name")
        @address.expects(:collection).returns(@collection)
        @collection.expects(:save)
      end

      it "adds the callback for primary key generation" do
        @address.save
        @address.id.should == "testing-street-name"
      end

    end

    context "when key is composite" do

      before do
        Address.key :street, :zip
        @address = Address.new(:street => "Testing Street Name", :zip => "94123")
        @address.expects(:collection).returns(@collection)
        @collection.expects(:save)
      end

      it "combines all fields" do
        @address.save
        @address.id.should == "testing-street-name-94123"
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
        @attributes = HashWithIndifferentAccess.new({ :test => "test" })
      end

      it "sets the attributes hash on the object" do
        person = Person.new(@attributes)
        person.attributes.should == @attributes
      end

    end

    context "with a primary key" do

      context "when the value for the key exists" do

        before do
          Address.key :street
          @address = Address.new(:street => "Test")
        end

        it "sets the primary key" do
          @address.id.should == "test"
        end

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
      @criteria = stub(:page => 1, :offset => "20")
    end

    context "when pagination parameters are passed" do

      before do
        @params = { :conditions => { :test => "Test" }, :page => 2, :per_page => 20 }
      end

      it "delegates to will paginate with the results" do
        Mongoid::Criteria.expects(:translate).with(:all, @params).returns(@criteria)
        @criteria.expects(:execute).with(Person).returns([])
        Person.paginate(@params)
      end

    end

    context "when pagination parameters are not passed" do

      before do
        @params = { :conditions => { :test => "Test" }}
      end

      it "delegates to will paginate with default values" do
        Mongoid::Criteria.expects(:translate).with(:all, @params).returns(@criteria)
        @criteria.expects(:execute).with(Person).returns([])
        Person.paginate(:conditions => { :test => "Test" })
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

  describe "#select" do

    it "returns a new criteria with select conditions added" do
      criteria = Person.select(:title, :age)
      criteria.options.should == { :fields => [ :title, :age ] }
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

  describe "#write_attributes" do

    context "on a child document" do

      context "when child is part of a has one" do

        before do
          @person = Person.new(:title => "Sir", :age => 30)
          @name = Name.new(:first_name => "Test", :last_name => "User")
          @person.name = @name
        end

        it "sets the child attributes on the parent" do
          @name.write_attributes(:first_name => "Test2", :last_name => "User2")
          @person.attributes[:name].should ==
            { :first_name => "Test2", :last_name => "User2" }
        end

      end

      context "when child is part of a has many" do

        before do
          @person = Person.new(:title => "Sir")
          @address = Address.new(:street => "Test")
          @person.addresses << @address
        end

        it "updates the child attributes on the parent" do
          @address.write_attributes(:street => "Test2")
          @person.attributes[:addresses].should == [{ :street => "Test2" }]
        end

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
