require "spec_helper"

describe Mongoid::Commands::DestroyAll do

  describe "#execute" do

    before do
      @doc = mock
      @docs = [@doc]
      @klass = mock
      @conditions = { :conditions => { :title => "Sir" } }
    end

    it "destroys each document that the criteria finds" do
      @klass.expects(:find).with(:all, @conditions).returns(@docs)
      Mongoid::Commands::Destroy.expects(:execute).with(@doc)
      Mongoid::Commands::DestroyAll.execute(@klass, @conditions)
    end

  end

end
