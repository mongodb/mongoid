require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

describe Mongoid::Criteria do

  describe "#select" do

    before do
      @criteria = Mongoid::Criteria.new
    end

    it "adds the options for limiting by fields" do
      @criteria.select(:title, :text)
      @criteria.options.should == { :fields => [ :title, :text ] }
    end

    it "returns self" do
      @criteria.select.should == @criteria
    end

  end

  describe "#where" do

    before do
      @criteria = Mongoid::Criteria.new
    end

    it "adds the clause to the selector" do
      @criteria.where(:title => "Title", :text => "Text")
      @criteria.selector.should == { :title => "Title", :text => "Text" }
    end

    it "returns self" do
      @criteria.where.should == @criteria
    end

  end

  describe "#order_by" do

    before do
      @criteria = Mongoid::Criteria.new
    end

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

  describe "#skip" do

    before do
      @criteria = Mongoid::Criteria.new
    end

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

  describe "#limit" do

    before do
      @criteria = Mongoid::Criteria.new
    end

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

end
