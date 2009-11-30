require "spec_helper"

describe Mongoid::Commands::Destroy do

  describe "#execute" do

    before do
      @collection = stub_everything
      @document = stub(:run_callbacks => true,
                       :collection => @collection,
                       :id => "1")
    end

    it "runs the before and after destroy callbacks" do
      @document.expects(:run_callbacks).with(:before_destroy)
      @document.expects(:run_callbacks).with(:after_destroy)
      Mongoid::Commands::Destroy.execute(@document)
    end

    it "removes the document from its collection" do
      @collection.expects(:remove).with({ :_id => @document.id })
      Mongoid::Commands::Destroy.execute(@document)
    end

  end

end
