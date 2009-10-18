require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

describe Mongoid::Criteria do

  before do
    @criteria = Mongoid::Criteria.new(:all)
  end

  describe "#all" do

    it "adds the $all query to the selector" do
      @criteria.all(:title => ["title1", "title2"])
      @criteria.selector.should == { :title => { "$all" => ["title1", "title2"] } }
    end

    it "returns self" do
      @criteria.all(:title => [ "title1" ]).should == @criteria
    end

  end

  describe "#excludes" do

    it "adds the $ne query to the selector" do
      @criteria.excludes(:title => "Bad Title", :text => "Bad Text")
      @criteria.selector.should == { :title => { "$ne" => "Bad Title"}, :text => { "$ne" => "Bad Text" } }
    end

    it "returns self" do
      @criteria.excludes(:title => "Bad").should == @criteria
    end

  end

  describe "#execute" do

    context "when type is :first" do

      it "calls find on the collection with the selector and options" do
        criteria = Mongoid::Criteria.new(:first)
        collection = mock
        Person.expects(:collection).returns(collection)
        collection.expects(:find_one).with(@criteria.selector, @criteria.options).returns({})
        criteria.execute(Person).should be_a_kind_of(Person)
      end

    end

    context "when type is not :first" do

      it "calls find on the collection with the selector and options" do
        criteria = Mongoid::Criteria.new(:all)
        collection = mock
        Person.expects(:collection).returns(collection)
        collection.expects(:find).with(@criteria.selector, @criteria.options).returns([])
        criteria.execute(Person).should == []
      end

    end

  end

  describe "#extras" do

    it "adds the extras to the options" do
      @criteria.extras({ :skip => 10 })
      @criteria.options.should == { :skip => 10 }
    end

    it "returns self" do
      @criteria.extras({}).should == @criteria
    end

  end

  describe "#id" do

    it "adds the _id query to the selector" do
      id = Mongo::ObjectID.new
      @criteria.id(id.to_s)
      @criteria.selector.should == { :_id => id }
    end

    it "returns self" do
      id = Mongo::ObjectID.new
      @criteria.id(id.to_s).should == @criteria
    end

  end

  describe "#in" do

    it "adds the $in clause to the selector" do
      @criteria.in(:title => ["title1", "title2"], :text => ["test"])
      @criteria.selector.should == { :title => { "$in" => ["title1", "title2"] }, :text => { "$in" => ["test"] } }
    end

    it "returns self" do
      @criteria.in(:title => ["title1"]).should == @criteria
    end

  end

  describe "#limit" do

    context "when value provided" do

      it "adds the limit to the options" do
        @criteria.limit(100)
        @criteria.options.should == { :limit => 100 }
      end

    end

    context "when value not provided" do

      it "defaults to 20" do
        @criteria.limit
        @criteria.options.should == { :limit => 20 }
      end

    end

    it "returns self" do
      @criteria.limit.should == @criteria
    end

  end

  describe "#not_in" do

    it "adds the exclusion to the selector" do
      @criteria.not_in(:title => ["title1", "title2"], :text => ["test"])
      @criteria.selector.should == { :title => { "$nin" => ["title1", "title2"] }, :text => { "$nin" => ["test"] } }
    end

    it "returns self" do
      @criteria.not_in(:title => ["title1"]).should == @criteria
    end

  end

  describe "#order_by" do

    context "when field names and direction specified" do

      it "adds the sort to the options" do
        @criteria.order_by([[:title, :asc], [:text, :desc]])
        @criteria.options.should == { :sort => [[:title, :asc], [:text, :desc]] }
      end

    end

    it "returns self" do
      @criteria.order_by.should == @criteria
    end

  end

  describe "#select" do

    it "adds the options for limiting by fields" do
      @criteria.select(:title, :text)
      @criteria.options.should == { :fields => [ :title, :text ] }
    end

    it "returns self" do
      @criteria.select.should == @criteria
    end

  end

  describe "#skip" do

    context "when value provided" do

      it "adds the skip value to the options" do
        @criteria.skip(20)
        @criteria.options.should == { :skip => 20 }
      end

    end

    context "when value not provided" do

      it "defaults to zero" do
        @criteria.skip
        @criteria.options.should == { :skip => 0 }
      end

    end

    it "returns self" do
      @criteria.skip.should == @criteria
    end

  end

  describe "#translate" do

    context "single argument as a string" do

      it "creates a new select criteria" do
        id = Mongo::ObjectID.new
        criteria = Mongoid::Criteria.translate(id.to_s)
        criteria.selector.should == { :_id => id }
      end

    end

    context "multiple arguments" do

      context "when :first, :conditions => {}" do

        before do
          @criteria = Mongoid::Criteria.translate(:first, :conditions => { :title => "Test" })
        end

        it "returns a criteria with a selector from the conditions" do
          @criteria.selector.should == { :title => "Test" }
        end

        it "returns a criteria with type :first" do
          @criteria.type.should == :first
        end

      end

      context "when :all, :conditions => {}" do

        before do
          @criteria = Mongoid::Criteria.translate(:all, :conditions => { :title => "Test" })
        end

        it "returns a criteria with a selector from the conditions" do
          @criteria.selector.should == { :title => "Test" }
        end

        it "returns a criteria with type :all" do
          @criteria.type.should == :all
        end

      end

      context "when :last, :conditions => {}" do

        before do
          @criteria = Mongoid::Criteria.translate(:last, :conditions => { :title => "Test" })
        end

        it "returns a criteria with a selector from the conditions" do
          @criteria.selector.should == { :title => "Test" }
        end

        it "returns a criteria with type :last" do
          @criteria.type.should == :last
        end

      end

      context "when options are provided" do

        before do
          @criteria = Mongoid::Criteria.translate(:last, :conditions => { :title => "Test" }, :skip => 10)
        end

        it "adds the criteria and the options" do
          @criteria.selector.should == { :title => "Test" }
          @criteria.options.should == { :skip => 10 }
        end

      end

    end

  end

  describe "#where" do

    it "adds the clause to the selector" do
      @criteria.where(:title => "Title", :text => "Text")
      @criteria.selector.should == { :title => "Title", :text => "Text" }
    end

    it "returns self" do
      @criteria.where.should == @criteria
    end

  end

end
