require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

describe Mongoid::Finders do

  before do
    @collection = mock
    @database = stub(:collection => @collection)
    Mongoid.stubs(:database).returns(@database)
  end

  after do
    Person.instance_variable_set(:@collection, nil)
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

  describe "#collection" do

    before do
      @person = Person.new
    end

    it "sets the collection name to the class pluralized" do
      @database.expects(:collection).with("people").returns(@collection)
      Person.collection
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
        @collection.expects(:find_one).with(:test => "Test" ).returns(@attributes)
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

  describe "#find_first" do

    before do
      @attributes = { :document_class => "Person" }
    end

    context "when a selector is provided" do

      it "finds the first document from the collection and instantiates it" do
        @collection.expects(:find_one).with(:test => "Test").returns(@attributes)
        Person.find_first(:conditions => {:test => "Test"}).attributes.should == @attributes
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
        @collection.expects(:find).with({ :test => "Test" }, {}).returns(@cursor)
        @cursor.expects(:collect).returns(@people)
        Person.find_all(:conditions => {:test => "Test"})
      end

    end

    context "when a selector is not provided" do

      it "finds from the collection and instantiate objects for each returned" do
        @collection.expects(:find).with(nil, {}).returns(@cursor)
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
      @collection.expects(:group).with([:title], nil, { :group => [] }, @reduce).returns(results)
      grouped = Person.group_by([:title], {})
      people = grouped.first["group"]
      people.first.should be_a_kind_of(Person)
    end

  end

  describe "#paginate" do

    before do
      @cursor = stub(:count => 100, :collect => [])
    end

    context "when pagination parameters are passed" do

      it "delegates to will paginate with the results" do
        @collection.expects(:find).with({ :test => "Test" }, { :sort => {}, :limit => 20, :offset => 20}).returns(@cursor)
        Person.paginate(:conditions => { :test => "Test" }, :page => 2, :per_page => 20)
      end

    end

    context "when pagination parameters are not passed" do

      it "delegates to will paginate with default values" do
        @collection.expects(:find).with({ :test => "Test" }, { :sort => {}, :limit => 20, :offset => 0}).returns(@cursor)
        Person.paginate(:conditions => { :test => "Test" })
      end

    end

    context "when sorting paramters provided" do

      it "adds the sorting parameters in the collection#find" do
        @collection.expects(:find).with({ :test => "Test" }, { :sort => { :test => -1}, :limit => 20, :offset => 0}).returns(@cursor)
        Person.paginate(:conditions => { :test => "Test" }, :sort => { :test => -1 })
      end

    end

  end

  describe "#paginate" do

    before do
      @cursor = stub(:count => 100, :collect => [])
    end

    context "when pagination parameters are passed" do

      it "delegates to will paginate with the results" do
        @collection.expects(:find).with({ :test => "Test" }, { :sort => {}, :limit => 20, :offset => 20}).returns(@cursor)
        Person.paginate(:conditions => { :test => "Test" }, :page => 2, :per_page => 20)
      end

    end

    context "when pagination parameters are not passed" do

      it "delegates to will paginate with default values" do
        @collection.expects(:find).with({ :test => "Test" }, { :sort => {}, :limit => 20, :offset => 0}).returns(@cursor)
        Person.paginate(:conditions => { :test => "Test" })
      end

    end

    context "when sorting paramters provided" do

      it "adds the sorting parameters in the collection#find" do
        @collection.expects(:find).with({ :test => "Test" }, { :sort => { :test => -1}, :limit => 20, :offset => 0}).returns(@cursor)
        Person.paginate(:conditions => { :test => "Test" }, :sort => { :test => -1 })
      end

    end

  end

end
