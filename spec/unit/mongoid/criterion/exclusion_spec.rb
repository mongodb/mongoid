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

    context "when existing ne criteria exists" do

      before do
        @criteria.excludes(:title => "Bad Title")
        @criteria.excludes(:text => "Bad Text")
      end

      it "appends to the selector" do
        @criteria.selector.should ==
          {
            :title =>
              { "$ne" => "Bad Title"},
            :text =>
              { "$ne" => "Bad Text" }
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

    context "when existing nin criteria exists" do

      before do
        @criteria.not_in(:title => ["title1", "title2"])
        @criteria.not_in(:title => ["title3"], :text => ["test"])
      end

      it "appends to the nin selector" do
        @criteria.selector.should == {
          :title => { "$nin" => ["title1", "title2", "title3"] },
          :text => { "$nin" => ["test"] }
        }
      end
    end
  end

  describe "#only" do

    context "when args are provided" do

      it "adds the options for limiting by fields" do
        @criteria.only(:title, :text)
        @criteria.options.should == { :fields => { :_type => 1, :title => 1, :text => 1 } }
      end

      it "returns self" do
        @criteria.only.should == @criteria
      end

      it "should assign the field list" do
        @criteria.without(:title, :text)
        @criteria.field_list == [:title, :text]
      end

    end

    context "when no args provided" do

      it "does not add the field option" do
        @criteria.only
        @criteria.options[:fields].should be_nil
      end

      it "should not assign the field list" do
        @criteria.only
        @criteria.field_list.should be_nil
      end

    end

  end

  describe "#without" do

    context "when args are provided" do

      it "adds the options for excluding the fields" do
        @criteria.without(:title, :text)
        @criteria.options.should == { :fields => { :title => 0, :text => 0 } }
      end

      it "returns self" do
        @criteria.without.should == @criteria
      end

    end

    context "when no args provided" do

      it "does not add the field option" do
        @criteria.without
        @criteria.options[:fields].should be_nil
      end

      it "should not assign the field list" do
        @criteria.without
        @criteria.field_list.should be_nil
      end

    end

  end

end
