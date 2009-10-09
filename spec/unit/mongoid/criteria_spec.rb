require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

describe Mongoid::Criteria do

  before do
    @criteria = Mongoid::Criteria.new
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

  describe "#select" do

    it "adds the clause to the selector" do
      @criteria.select(:title => "Title", :text => "Text")
      @criteria.selector.should == { :title => "Title", :text => "Text" }
    end

    it "returns self" do
      @criteria.select.should == @criteria
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
        @criteria.order_by(:title => 1, :text => -1)
        @criteria.options.should == { :sort => { :title => 1, :text => -1 }}
      end

    end

    it "returns self" do
      @criteria.order_by.should == @criteria
    end

  end

  describe "#only" do

    it "adds the options for limiting by fields" do
      @criteria.only(:title, :text)
      @criteria.options.should == { :fields => [ :title, :text ] }
    end

    it "returns self" do
      @criteria.only.should == @criteria
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

end
