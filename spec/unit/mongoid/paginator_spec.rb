require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

describe Mongoid::Paginator do

  describe "#limit" do

    context "when per_page is defined" do

      before do
        @options = { :per_page => 50 }
        @paginator = Mongoid::Paginator.new(@options)
      end

      it "returns the per_page value" do
        @paginator.limit.should == 50
      end

    end

    context "when per_page is not defined" do

      before do
        @options = {}
        @paginator = Mongoid::Paginator.new(@options)
      end

      it "returns the default of 20" do
        @paginator.limit.should == 20
      end

    end

  end

  describe "#offset" do

    context "when page is defined" do

      before do
        @options = { :page => 11 }
        @paginator = Mongoid::Paginator.new(@options)
      end

      it "returns the page value - 1 * limit" do
        @paginator.offset.should == 200
      end

    end

    context "when page is not defined" do

      before do
        @options = {}
        @paginator = Mongoid::Paginator.new(@options)
      end

      it "returns the default of 0" do
        @paginator.offset.should == 0
      end

    end

  end

  describe "#options" do

    it "returns a hash of the limit and offset" do
      @paginator = Mongoid::Paginator.new
      @paginator.options.should == { :limit => 20, :offset => 0 }
    end

  end

end
