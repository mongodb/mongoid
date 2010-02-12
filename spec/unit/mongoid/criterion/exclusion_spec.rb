require "spec_helper"

describe Mongoid::Criterion::Exclusion do

  before do
    @criteria = Mongoid::Criteria.new(Person)
    @canvas_criteria = Mongoid::Criteria.new(Canvas)
  end

  describe "#excludes" do

    it "adds the $ne query to the selector" do
      @criteria.excludes(:title => "Bad Title", :text => "Bad Text")
      @criteria.selector.should ==
        {
          :title =>
            { "$ne" => "Bad Title"},
          :text =>
            { "$ne" => "Bad Text" }
        }
    end

    it "returns self" do
      @criteria.excludes(:title => "Bad").should == @criteria
    end

    context "when passing an id" do

      it "accepts id" do
        @criteria.excludes(:id => "1")
        @criteria.selector.should ==
          {
            :_id => { "$ne" => "1" }
          }
      end

      it "accepts _id" do
        @criteria.excludes(:_id => "1")
        @criteria.selector.should ==
          {
            :_id => { "$ne" => "1" }
          }
      end

    end

  end

  describe "#not_in" do

    it "adds the exclusion to the selector" do
      @criteria.not_in(:title => ["title1", "title2"], :text => ["test"])
      @criteria.selector.should == {
        :title => { "$nin" => ["title1", "title2"] },
        :text => { "$nin" => ["test"] }
      }
    end

    it "returns self" do
      @criteria.not_in(:title => ["title1"]).should == @criteria
    end

  end

  describe "#only" do

    context "when args are provided" do

      it "adds the options for limiting by fields" do
        @criteria.only(:title, :text)
        @criteria.options.should == { :fields => [ :title, :text ] }
      end

      it "returns self" do
        @criteria.only.should == @criteria
      end

    end

    context "when no args provided" do

      it "does not add the field option" do
        @criteria.only
        @criteria.options[:fields].should be_nil
      end

    end

  end

end
