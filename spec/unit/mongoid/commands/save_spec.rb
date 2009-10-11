require File.join(File.dirname(__FILE__), "/../../../spec_helper.rb")

describe Mongoid::Commands::Save do

  describe "#execute" do

    before do
      @document = stub
    end

    context "when document is valid" do

      before do
        @document.expects(:valid?).returns(true)
      end

      it "runs the before and after callbacks" do
        @document.expects(:run_callbacks).with(:before_save)
        @document.expects(:run_callbacks).with(:after_save)
        Mongoid::Commands::Save.execute(@document)
      end

    end

    context "when document is invalid" do

      before do
        @document.expects(:valid?).returns(false)
      end

    end

  end

end
