require "spec_helper"

describe Mongoid::Finders do

  before do
    @collection = stub(:name => "people")
    @database = stub(:collection => @collection)
    Mongoid.stubs(:database).returns(@database)
  end

  describe ".all" do

    before do
      @conditions = { :conditions => { :test => "Test" } }
    end

    context "when a selector is provided" do

      it "finds from the collection and instantiate objects for each returned" do
        Mongoid::Criteria.expects(:translate).with(Person, @conditions)
        Person.all(@conditions)
      end

    end

    context "when a selector is not provided" do

      it "finds from the collection and instantiate objects for each returned" do
        Mongoid::Criteria.expects(:translate).with(Person, nil)
        Person.all
      end

    end

  end

  describe ".all_in" do

    it "returns a new criteria with select conditions added" do
      criteria = Person.all_in(:aliases => [ "Bond", "007" ])
      criteria.selector.should == { :aliases => { "$all" => [ "Bond", "007" ] } }
    end

  end

  describe ".any_in" do

    it "returns a new criteria with select conditions added" do
      criteria = Person.any_in(:aliases => [ "Bond", "007" ])
      criteria.selector.should == { :aliases => { "$in" => [ "Bond", "007" ] } }
    end

  end

  describe ".count" do

    before do
      @conditions = { :conditions => { :title => "Sir" } }
      @criteria = mock
    end

    it "delegates to the criteria api" do
      Mongoid::Criteria.expects(:translate).with(Person, @conditions).returns(@criteria)
      @criteria.expects(:count).returns(10)
      Person.count(@conditions).should == 10
    end

    context "when no options provided" do

      it "adds in the default parameters" do
        Mongoid::Criteria.expects(:translate).with(Person, nil).returns(@criteria)
        @criteria.expects(:count).returns(10)
        Person.count.should == 10
      end

    end

  end

  describe ".exists?" do

    before do
      @conditions = { :conditions => { :title => "Sir" } }
      @criteria = mock
    end

    it "should be true if there are document in collection with options" do
      Mongoid::Criteria.expects(:translate).with(Person, @conditions).returns(@criteria)
      @criteria.expects(:limit).with(1).returns(@criteria)
      @criteria.expects(:count).returns(1)
      Person.exists?(@conditions).should be_true
    end

    it 'should false if there are no document in collection with options' do
      Mongoid::Criteria.expects(:translate).with(Person, @conditions).returns(@criteria)
      @criteria.expects(:limit).with(1).returns(@criteria)
      @criteria.expects(:count).returns(0)
      Person.exists?(@conditions).should be_false
    end

    context "when no options provided" do

      it "should be true if there are document in collection" do
        Mongoid::Criteria.expects(:translate).with(Person, nil).returns(@criteria)
        @criteria.expects(:limit).with(1).returns(@criteria)
        @criteria.expects(:count).returns(1)
        Person.exists?.should be_true
      end

      it "should be false if there are no document in collection" do
        Mongoid::Criteria.expects(:translate).with(Person, nil).returns(@criteria)
        @criteria.expects(:limit).with(1).returns(@criteria)
        @criteria.expects(:count).returns(1)
        Person.exists?.should be_true
      end

    end

  end

  describe ".excludes" do

    it "returns a new criteria with select conditions added" do
      criteria = Person.excludes(:title => "Sir")
      criteria.selector.should == { :title => { "$ne" => "Sir" } }
    end

  end

  describe ".find" do

    before do
      @attributes = {}
      @criteria = mock
    end

    context "when an id is passed in" do

      before do
        @id = BSON::ObjectId.new.to_s
      end

      it "delegates to criteria" do
        Mongoid::Criteria.expects(:translate).with(Person, @id.to_s).returns(Person.new)
        Person.find(@id.to_s)
      end

      context "when no document is found" do

        it "raises an error" do
          @error = Mongoid::Errors::DocumentNotFound.new(Person, @id.to_s)
          Mongoid::Criteria.expects(:translate).with(Person, @id.to_s).raises(@error)
          lambda { Person.find(@id.to_s) }.should raise_error
        end

      end

      context "when it is called with a nil value" do

        it "raises an InvalidOptions error" do
          lambda { Person.find(nil) }.should raise_error(Mongoid::Errors::InvalidOptions)
        end

      end

    end

    context "when an array of ids is passed in" do

      before do
        @ids = []
        3.times { @ids << BSON::ObjectId.new.to_s }
      end

      it "delegates to the criteria" do

      end

    end

    context "when nil passed in" do

      it "raises an error" do
        lambda { Person.find(nil) }.should raise_error
      end

    end

    context "when finding first" do

      it "delegates to criteria" do
        Mongoid::Criteria.expects(:translate).with(Person, :conditions => { :test => "Test" }).returns(@criteria)
        @criteria.expects(:one).returns(@attributes)
        Person.find(:first, :conditions => { :test => "Test" })
      end

    end

    context "when finding all" do

      before do
        @conditions = { :conditions => { :test => "Test" } }
      end

      it "delegates to find_all" do
        Mongoid::Criteria.expects(:translate).with(Person, @conditions).returns(@criteria)
        Person.find(:all, @conditions)
      end

    end

    context "when sorting" do

      before do
        @conditions = { :conditions => { :test => "Test" }, :sort => { :test => -1 } }
      end

      it "adds the sort parameters for the collection call" do
        Mongoid::Criteria.expects(:translate).with(Person, @conditions).returns(@criteria)
        Person.find(:all, @conditions)
      end
    end

  end

  describe ".find_or_create_by" do

    before do
      @person = Person.new(:age => 30)
      @criteria = mock
    end

    context "when the document is found" do

      it "returns the document" do
        Mongoid::Criteria.expects(:translate).with(
          Person, :conditions => { :age => 30 }
        ).returns(@criteria)
        @criteria.expects(:one).returns(@person)
        Person.find_or_create_by(:age => 30).should == @person
      end

    end

    context "when the document is not found" do

      it "creates a new document" do
        Mongoid::Criteria.expects(:translate).with(
          Person, :conditions => { :age => 30 }
        ).returns(@criteria)
        @criteria.expects(:one).returns(nil)
        Person.expects(:create).returns(@person)
        person = Person.find_or_create_by(:age => 30)
        person.should be_a_kind_of(Person)
        person.age.should == 30
      end

    end

  end

  describe ".find_or_initialize_by" do

    before do
      @person = Person.new(:age => 30)
      @criteria = mock
    end

    context "when the document is found" do

      it "returns the document" do
        Mongoid::Criteria.expects(:translate).with(
          Person, :conditions => { :age => 30 }
        ).returns(@criteria)
        @criteria.expects(:one).returns(@person)
        Person.find_or_initialize_by(:age => 30).should == @person
      end

    end

    context "when the document is not found" do

      it "returns a new document with the conditions" do
        Mongoid::Criteria.expects(:translate).with(
          Person, :conditions => { :age => 30 }
        ).returns(@criteria)
        @criteria.expects(:one).returns(nil)
        person = Person.find_or_initialize_by(:age => 30)
        person.should be_a_kind_of(Person)
        person.should be_a_new_record
        person.age.should == 30
      end

    end

  end

  describe ".first" do

    before do
      @criteria = mock
      @conditions = { :conditions => { :test => "Test" } }
    end

    context "when a selector is provided" do

      it "finds the first document from the collection and instantiates it" do
        Mongoid::Criteria.expects(:translate).with(Person, @conditions).returns(@criteria)
        @criteria.expects(:one)
        Person.first(@conditions)
      end

    end

    context "when a selector is not provided" do

      it "finds the first document from the collection and instantiates it" do
        Mongoid::Criteria.expects(:translate).with(Person, nil).returns(@criteria)
        @criteria.expects(:one)
        Person.first
      end

    end

  end

  describe ".last" do

    before do
      @criteria = mock
    end

    it "finds the last document by the id" do
      Mongoid::Criteria.expects(:translate).with(Person, nil).returns(@criteria)
      @criteria.expects(:last)
      Person.last
    end

  end

  describe ".max" do

    before do
      @criteria = mock
    end

    it "returns the sum of a new criteria" do
      Person.expects(:criteria).returns(@criteria)
      @criteria.expects(:max).with(:age).returns(50.0)
      Person.max(:age).should == 50.0
    end

  end

  describe ".min" do

    before do
      @criteria = mock
    end

    it "returns the sum of a new criteria" do
      Person.expects(:criteria).returns(@criteria)
      @criteria.expects(:min).with(:age).returns(50.0)
      Person.min(:age).should == 50.0
    end

  end

  describe ".not_in" do

    it "returns a new criteria with select conditions added" do
      criteria = Person.not_in(:aliases => [ "Bond", "007" ])
      criteria.selector.should == { :aliases => { "$nin" => [ "Bond", "007" ] } }
    end

  end

  describe ".paginate" do

    before do
      @criteria = stub(:page => 1, :per_page => "20", :count => 100)
    end

    context "when pagination parameters are passed" do

      before do
        @params = { :conditions => { :test => "Test" }, :page => 2, :per_page => 20 }
      end

      it "delegates to will paginate with the results" do
        Mongoid::Criteria.expects(:translate).with(Person, @params).returns(@criteria)
        @criteria.expects(:paginate).returns([])
        Person.paginate(@params)
      end

    end

    context "when pagination parameters are not passed" do

      before do
        @params = { :conditions => { :test => "Test" }}
      end

      it "delegates to will paginate with default values" do
        Mongoid::Criteria.expects(:translate).with(Person, @params).returns(@criteria)
        @criteria.expects(:paginate).returns([])
        Person.paginate(:conditions => { :test => "Test" })
      end

    end

  end

  describe ".only" do

    it "returns a new criteria with select conditions added" do
      criteria = Person.only(:title, :age)
      criteria.options.should == { :fields => [ :title, :age ] }
    end

  end

  describe ".sum" do

    before do
      @criteria = mock
    end

    it "returns the sum of a new criteria" do
      Person.expects(:criteria).returns(@criteria)
      @criteria.expects(:sum).with(:age).returns(50.0)
      sum = Person.sum(:age)
      sum.should == 50.0
    end

  end

  describe ".where" do

    it "returns a new criteria with select conditions added" do
      criteria = Person.where(:title => "Sir")
      criteria.selector.should == { :title => "Sir" }
    end

  end

  describe ".near" do

    it "returns a new criteria with select conditions added" do
      criteria = Address.near(:latlng => [37.761523, -122.423575, 1])
      criteria.selector.should == { :latlng => { "$near" => [37.761523, -122.423575, 1] } }
    end

  end

end
