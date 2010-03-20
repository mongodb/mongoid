require "spec_helper"

describe Mongoid::Commands::Create do

  describe "#execute" do

    before do
      @document = stub(:run_callbacks)
    end

    it "executes a save command" do
      @document.expects(:run_callbacks).yields
      Mongoid::Commands::Save.expects(:execute).with(@document, true).returns(@document)
      Mongoid::Commands::Create.execute(@document)
    end

    it "runs the before and after create callbacks" do
      @document.expects(:run_callbacks).with(:create).yields
      Mongoid::Commands::Save.expects(:execute).with(@document, true).returns(@document)
      Mongoid::Commands::Create.execute(@document)
    end

    it "returns the document" do
      @document.expects(:run_callbacks).yields
      Mongoid::Commands::Save.expects(:execute).with(@document, true).returns(@document)
      Mongoid::Commands::Create.execute(@document).should == @document
    end

  end

end
