require "spec_helper"

describe Mongoid::Commands::DeleteAll do

  describe "#execute" do

    before do
      @doc = mock
      @docs = [@doc]
      @klass = stub(:name => "Person")
    end

    context "when conditions supplied" do

      before do
        @collection = mock
        @conditions = { :conditions => { :title => "Sir" } }
      end

      it "deletes each document that the criteria finds" do
        @klass.expects(:collection).returns(@collection)
        @collection.expects(:remove).with(@conditions[:conditions].merge(:_type => "Person"))
        Mongoid::Commands::DeleteAll.execute(@klass, @conditions)
      end

    end

    context "when no conditions supplied" do

      before do
        @collection = mock
      end

      it "drops the collection" do
        @klass.expects(:collection).returns(@collection)
        @collection.expects(:drop)
        Mongoid::Commands::DeleteAll.execute(@klass)
      end

    end

    context "when empty conditions supplied" do

      before do
        @collection = mock
      end

      it "drops the collection" do
        @klass.expects(:collection).returns(@collection)
        @collection.expects(:drop)
        Mongoid::Commands::DeleteAll.execute(@klass, {})
      end

    end

  end

end
