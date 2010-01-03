require "spec_helper"

describe Mongoid::Finders do

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

  describe ".find" do

    before do
      @attributes = {}
      @criteria = mock
    end

    context "when an id is passed in" do

      before do
        @id = Mongo::ObjectID.new.to_s
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

  describe ".find_by_id" do

    before do
      @criteria = mock
    end

    it "delegates to find with an id parameter" do
      Mongoid::Criteria.expects(:translate).with(Person, :conditions => { "_id" => "1" }).returns(@criteria)
      @criteria.expects(:one).returns(Person.new)
      Person.find_by_id("1")
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

  describe ".method_missing" do

    context "with a finder method name" do

      before do
        @criteria = stub
        @document = stub
        @conditions = { "title" => "Sir", "age" => 30 }
      end

      it "executes the finder" do
        Mongoid::Criteria.expects(:translate).with(Person, :conditions => @conditions).returns(@criteria)
        @criteria.expects(:one).returns(@document)
        Person.find_by_title_and_age("Sir", 30)
      end

    end

    context "with a finder or creation method name" do

      before do
        @criteria = stub
        @document = stub
        @conditions = { "title" => "Sir", "age" => 30 }
      end

      context "when document is found" do

        it "returns the document" do
          Mongoid::Criteria.expects(:translate).with(Person, :conditions => @conditions).returns(@criteria)
          @criteria.expects(:one).returns(@document)
          Person.find_or_initialize_by_title_and_age("Sir", 30).should == @document
        end

      end

      context "when document is not found" do

        it "instantiates a new document" do
          Mongoid::Criteria.expects(:translate).with(Person, :conditions => @conditions).returns(@criteria)
          @criteria.expects(:one).returns(nil)
          new_doc = Person.find_or_initialize_by_title_and_age("Sir", 30)
          new_doc.new_record?.should be_true
          new_doc.title.should == "Sir"
          new_doc.age.should == 30
        end

      end

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

  describe ".where" do

    it "returns a new criteria with select conditions added" do
      criteria = Person.where(:title => "Sir")
      criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :title => "Sir" }
    end

  end

end
