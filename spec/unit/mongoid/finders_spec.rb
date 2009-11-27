require File.expand_path(File.join(File.dirname(__FILE__), "/../../spec_helper.rb"))

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
      @cursor = stub(:count => 100)
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

  describe ".count" do

    before do
      @params = { :conditions => { :title => "Sir" } }
      @criteria = mock
    end

    it "delegates to the criteria api" do
      Mongoid::Criteria.expects(:translate).with(@params).returns(@criteria)
      @criteria.expects(:count).with(Person).returns(10)
      Person.count(@params).should == 10
    end

    context "when no options provided" do

      it "adds in the default parameters" do
        Mongoid::Criteria.expects(:translate).with(nil).returns(@criteria)
        @criteria.expects(:count).with(Person).returns(10)
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
        @cursor = stub(:count => 100)
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
        @cursor = stub(:count => 50)
        @people = []
      end

      it "adds the sort parameters for the collection call" do
        @collection.expects(:find).with({ :test => "Test" }, { :sort => { :test => -1 }}).returns(@cursor)
        @cursor.expects(:collect).returns(@people)
        Person.find(:all, :conditions => { :test => "Test" }, :sort => { :test => -1 })
      end
    end

  end

  describe ".find_by_id" do

    before do
      @criteria = stub_everything
    end

    it "delegates to find with an id parameter" do
      Mongoid::Criteria.expects(:translate).with(:first, :conditions => { "_id" => "1" }).returns(@criteria)
      Person.find_by_id("1")
    end

  end

  describe ".first" do

    before do
      @attributes = { "age" => 100 }
    end

    context "when a selector is provided" do

      it "finds the first document from the collection and instantiates it" do
        @collection.expects(:find_one).with({ :test => "Test" }, {}).returns(@attributes)
        Person.first(:conditions => {:test => "Test"}).attributes.except(:_id).should == @attributes
      end

    end

    context "when a selector is not provided" do

      it "finds the first document from the collection and instantiates it" do
        @collection.expects(:find_one).with(nil, {}).returns(@attributes)
        Person.first.attributes.except(:_id).should == @attributes
      end

    end

  end

  describe ".last" do

    before do
      @attributes = { :_id => 1, :title => "Sir" }
      @collection.expects(:find_one).with({}, :sort => [[:_id, :desc]]).returns(@attributes)
    end

    it "finds the last document by the id" do
      Person.last.should == Person.instantiate(@attributes)
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
        Mongoid::Criteria.expects(:translate).with(:first, :conditions => @conditions).returns(@criteria)
        @criteria.expects(:execute).with(Person).returns(@document)
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
          Mongoid::Criteria.expects(:translate).with(:first, :conditions => @conditions).returns(@criteria)
          @criteria.expects(:execute).with(Person).returns(@document)
          Person.find_or_initialize_by_title_and_age("Sir", 30).should == @document
        end

      end

      context "when document is not found" do

        it "instantiates a new document" do
          Mongoid::Criteria.expects(:translate).with(:first, :conditions => @conditions).returns(@criteria)
          @criteria.expects(:execute).with(Person).returns(nil)
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
        Mongoid::Criteria.expects(:translate).with(:all, @params).returns(@criteria)
        @criteria.expects(:paginate).with(Person).returns([])
        Person.paginate(@params)
      end

    end

    context "when pagination parameters are not passed" do

      before do
        @params = { :conditions => { :test => "Test" }}
      end

      it "delegates to will paginate with default values" do
        Mongoid::Criteria.expects(:translate).with(:all, @params).returns(@criteria)
        @criteria.expects(:paginate).with(Person).returns([])
        Person.paginate(:conditions => { :test => "Test" })
      end

    end

  end

  describe ".select" do

    it "returns a new criteria with select conditions added" do
      criteria = Person.select(:title, :age)
      criteria.options.should == { :fields => [ :title, :age ] }
    end

  end

end
