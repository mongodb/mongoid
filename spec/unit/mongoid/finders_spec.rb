require "spec_helper"

describe Mongoid::Finders do

  let(:collection) do
    stub(:name => "people")
  end

  let(:database) do
    stub(:collection => collection)
  end

  before do
    Mongoid.stubs(:database).returns(database)
  end

  describe ".all" do

    let(:conditions) do
      { :conditions => { :test => "Test" } }
    end

    context "when a selector is provided" do

      before do
        Mongoid::Criteria.expects(:translate).with(Person, false, conditions)
      end

      it "finds from the collection and instantiate objects for each returned" do
        Person.all(conditions)
      end
    end

    context "when a selector is not provided" do

      before do
        Mongoid::Criteria.expects(:translate).with(Person, false, nil)
      end

      it "finds from the collection and instantiate objects for each returned" do
        Person.all
      end
    end
  end

  describe ".all_in" do

    let(:criteria) do
      Person.all_in(:aliases => [ "Bond", "007" ])
    end

    it "returns a new criteria with select conditions added" do
      criteria.selector.should == { :aliases => { "$all" => [ "Bond", "007" ] } }
    end
  end

  describe ".any_in" do

    let(:criteria) do
      Person.any_in(:aliases => [ "Bond", "007" ])
    end

    it "returns a new criteria with select conditions added" do
      criteria.selector.should == { :aliases => { "$in" => [ "Bond", "007" ] } }
    end
  end

  describe ".count" do

    let(:conditions) do
      { :conditions => { :title => "Sir" } }
    end

    let(:criteria) do
      stub
    end

    context "with options provided" do

      before do
        Mongoid::Criteria.expects(
          :translate
        ).with(Person, false, conditions).returns(criteria)
        criteria.expects(:count).returns(10)
      end

      it "delegates to the criteria api" do
        Person.count(conditions).should == 10
      end
    end

    context "when no options provided" do

      before do
        Mongoid::Criteria.expects(
          :translate
        ).with(Person, false, nil).returns(criteria)
        criteria.expects(:count).returns(10)
      end

      it "adds in the default parameters" do
        Person.count.should == 10
      end
    end
  end

  describe ".exists?" do

    let(:criteria) do
      stub
    end

    context "when options are provided" do

      let(:conditions) do
        { :conditions => { :title => "Sir" } }
      end

      before do
        Mongoid::Criteria.expects(
          :translate
        ).with(Person, false, conditions).returns(criteria)
        criteria.expects(:limit).with(1).returns(criteria)
      end

      context "when count is greater than zero" do

        before do
          criteria.expects(:count).returns(1)
        end

        it "returns true" do
          Person.exists?(conditions).should be_true
        end
      end

      context "when the count is zero" do

        before do
          criteria.expects(:count).returns(0)
        end

        it "returns false" do
          Person.exists?(conditions).should be_false
        end
      end
    end

    context "when no options are provided" do

      before do
        Mongoid::Criteria.expects(
          :translate
        ).with(Person, false, nil).returns(criteria)
        criteria.expects(:limit).with(1).returns(criteria)
      end

      context "when count is greater than zero" do

        before do
          criteria.expects(:count).returns(1)
        end

        it "returns true" do
          Person.exists?.should be_true
        end
      end

      context "when the count is zero" do

        before do
          criteria.expects(:count).returns(0)
        end

        it "returns false" do
          Person.exists?.should be_false
        end
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

    let(:attributes) do
      {}
    end

    let(:criteria) do
      stub
    end

    context "when an id is provided" do

      let(:id) do
        BSON::ObjectId.new
      end

      context "when a document is found" do

        let(:person) do
          Person.new
        end

        before do
          Mongoid::Criteria.expects(
            :translate
          ).with(Person, false, id).returns(person)
        end

        it "returns the document" do
          Person.find(id).should == person
        end
      end

      context "when no document is found" do

        let(:error) do
          Mongoid::Errors::DocumentNotFound.new(Person, id)
        end

        before do
          Mongoid::Criteria.expects(
            :translate
          ).with(Person, false, id).raises(error)
        end

        it "raises an error" do
          expect { Person.find(id) }.to raise_error
        end
      end

      context "when it is called with a nil value" do

        it "raises an InvalidOptions error" do
          expect {
            Person.find(nil)
          }.to raise_error(Mongoid::Errors::InvalidOptions)
        end
      end
    end

    context "when an array of ids is passed in" do

      let(:ids) do
        3.times.collect { BSON::ObjectId.new }
      end

      context "when a document is found" do

        let(:person) do
          Person.new
        end

        before do
          Mongoid::Criteria.expects(
            :translate
          ).with(Person, false, ids).returns([ person ])
        end

        it "returns the document" do
          Person.find(ids).should == [ person ]
        end
      end

      context "when no document is found" do

        let(:error) do
          Mongoid::Errors::DocumentNotFound.new(Person, ids)
        end

        before do
          Mongoid::Criteria.expects(
            :translate
          ).with(Person, false, ids).raises(error)
        end

        it "raises an error" do
          expect { Person.find(ids) }.to raise_error
        end
      end
    end

    context "when finding first" do

      let(:conditions) do
        { :test => "Test" }
      end

      before do
        Mongoid::Criteria.expects(
          :translate
        ).with(Person, false, conditions).returns(criteria)
        criteria.expects(:one).returns(Person.new)
      end

      it "delegates to criteria" do
        Person.find(:first, conditions).should be_a(Person)
      end
    end

    context "when finding all" do

      let(:conditions) do
        { :conditions => { :test => "Test" } }
      end

      before do
        Mongoid::Criteria.expects(
          :translate
        ).with(Person, false, conditions).returns(criteria)
      end

      it "delegates to find_all" do
        Person.find(:all, conditions)
      end
    end

    context "when sorting" do

      let(:conditions) do
        { :conditions => { :test => "Test" }, :sort => { :test => -1 } }
      end

      before do
        Mongoid::Criteria.expects(
          :translate
        ).with(Person, false, conditions).returns(criteria)
      end

      it "adds the sort parameters for the collection call" do
        Person.find(:all, conditions)
      end
    end
  end

  describe ".find_or_create_by" do

    let(:person) do
      Person.new(:age => 30)
    end

    let(:criteria) do
      stub
    end

    context "when the document is found" do

      before do
        Mongoid::Criteria.expects(:translate).with(
          Person, false, :conditions => { :age => 30 }
        ).returns(criteria)
        criteria.expects(:one).returns(person)
      end

      it "returns the document" do
        Person.find_or_create_by(:age => 30).should == person
      end
    end

    context "when the document is not found" do

      before do
        Mongoid::Criteria.expects(:translate).with(
          Person, false, :conditions => { :age => 30 }
        ).returns(criteria)
        criteria.expects(:one).returns(nil)
        Person.expects(:create).returns(person)
      end

      let(:found) do
        Person.find_or_create_by(:age => 30)
      end

      it "creates a new document" do
        found.should be_a_kind_of(Person)
      end

      it "sets the attributes" do
        found.age.should == 30
      end
    end
  end

  describe ".find_or_initialize_by" do

    let(:person) do
      Person.new(:age => 30)
    end

    let(:criteria) do
      stub
    end

    context "when the document is found" do

      before do
        Mongoid::Criteria.expects(:translate).with(
          Person, false, :conditions => { :age => 30 }
        ).returns(criteria)
        criteria.expects(:one).returns(person)
      end

      it "returns the document" do
        Person.find_or_initialize_by(:age => 30).should == person
      end
    end

    context "when the document is not found" do

      before do
        Mongoid::Criteria.expects(:translate).with(
          Person, false, :conditions => { :age => 30 }
        ).returns(criteria)
        criteria.expects(:one).returns(nil)
      end

      let(:found) do
        Person.find_or_initialize_by(:age => 30)
      end

      it "creates a new document" do
        found.should be_a_kind_of(Person)
      end

      it "sets the attributes" do
        found.age.should == 30
      end
    end
  end

  describe ".first" do

    let(:criteria) do
      stub
    end

    let(:conditions) do
      { :conditions => { :test => "Test" } }
    end

    context "when a selector is provided" do

      before do
        Mongoid::Criteria.expects(
          :translate
        ).with(Person, false, conditions).returns(criteria)
        criteria.expects(:one)
      end

      it "returns the first document in the collection" do
        Person.first(conditions)
      end
    end

    context "when a selector is not provided" do

      before do
        Mongoid::Criteria.expects(
          :translate
        ).with(Person, false, nil).returns(criteria)
        criteria.expects(:one)
      end

      it "finds the first document from the collection and instantiates it" do
        Person.first
      end
    end
  end

  describe ".last" do

    let(:criteria) do
      stub
    end

    before do
      Mongoid::Criteria.expects(
        :translate
      ).with(Person, false, nil).returns(criteria)
      criteria.expects(:last)
    end

    it "finds the last document by the id" do
      Person.last
    end
  end

  describe ".max" do

    let(:criteria) do
      stub
    end

    before do
      Person.expects(:criteria).returns(criteria)
      criteria.expects(:max).with(:age).returns(50.0)
    end

    it "returns the sum of a new criteria" do
      Person.max(:age).should == 50.0
    end
  end

  describe ".min" do

    let(:criteria) do
      stub
    end

    before do
      Person.expects(:criteria).returns(criteria)
      criteria.expects(:min).with(:age).returns(50.0)
    end

    it "returns the sum of a new criteria" do
      Person.min(:age).should == 50.0
    end
  end

  describe ".not_in" do

    let(:criteria) do
      Person.not_in(:aliases => [ "Bond", "007" ])
    end

    it "returns a new criteria with select conditions added" do
      criteria.selector.should == { :aliases => { "$nin" => [ "Bond", "007" ] } }
    end
  end

  describe ".paginate" do

    let(:criteria) do
      stub(:page => 1, :per_page => "20", :count => 100)
    end

    context "when pagination parameters are passed" do

      let(:params) do
        { :conditions => { :test => "Test" }, :page => 2, :per_page => 20 }
      end

      before do
        Mongoid::Criteria.expects(
          :translate
        ).with(Person, false, params).returns(criteria)
        criteria.expects(:paginate).returns([])
      end

      it "delegates to will paginate with the results" do
        Person.paginate(params)
      end
    end

    context "when pagination parameters are not passed" do

      let(:params) do
        { :conditions => { :test => "Test" }}
      end

      before do
        Mongoid::Criteria.expects(
          :translate
        ).with(Person, false, params).returns(criteria)
        criteria.expects(:paginate).returns([])
      end

      it "delegates to will paginate with default values" do
        Person.paginate(:conditions => { :test => "Test" })
      end
    end
  end

  describe ".only" do

    let(:criteria) do
      Person.only(:title, :age)
    end

    it "returns a new criteria with select conditions added" do
      criteria.options.should == { :fields => [ :title, :age ] }
    end
  end

  describe ".sum" do

    let(:criteria) do
      stub
    end

    before do
      Person.expects(:criteria).returns(criteria)
      criteria.expects(:sum).with(:age).returns(50.0)
    end

    it "returns the sum of a new criteria" do
      Person.sum(:age).should == 50.0
    end
  end

  describe ".where" do

    let(:criteria) do
      Person.where(:title => "Sir")
    end

    it "returns a new criteria with select conditions added" do
      criteria.selector.should == { :title => "Sir" }
    end
  end

  describe ".near" do

    let(:criteria) do
      Address.near(:latlng => [37.761523, -122.423575, 1])
    end

    it "returns a new criteria with select conditions added" do
      criteria.selector.should ==
        { :latlng => { "$near" => [37.761523, -122.423575, 1] } }
    end
  end
end
