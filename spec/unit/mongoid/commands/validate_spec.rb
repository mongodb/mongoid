require File.expand_path(File.join(File.dirname(__FILE__), "/../../../spec_helper.rb"))

describe Mongoid::Commands::Validate do

  describe "#execute" do

    before do
      @document = stub(:run_callbacks)
    end

    it "validates the document" do
      @document.expects(:valid?).returns(true)
      Mongoid::Commands::Validate.execute(@document).should be_true
    end

    it "runs the before and after validate callbacks" do
      @document.expects(:valid?).returns(true)
      @document.expects(:run_callbacks).with(:before_validation)
      @document.expects(:run_callbacks).with(:after_validation)
      Mongoid::Commands::Validate.execute(@document)
    end

  end

end
