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
    
  end

end