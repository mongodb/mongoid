require File.join(File.dirname(__FILE__), "/../../../spec_helper.rb")

describe Mongoid::Commands::DeleteAll do

  describe "#execute" do

    before do
      @doc = mock
      @docs = [@doc]
      @klass = mock
      @conditions = { :conditions => { :title => "Sir" } }
    end

    it "destroys each document that the criteria finds" do
      @klass.expects(:find).with(:all, @conditions).returns(@docs)
      Mongoid::Commands::Delete.expects(:execute).with(@doc)
      Mongoid::Commands::DeleteAll.execute(@klass, @conditions)
    end

  end

end
