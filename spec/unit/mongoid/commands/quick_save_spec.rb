require "spec_helper"

describe Mongoid::Commands::QuickSave do

  describe "#execute" do

    before do
      @collection = mock
      @document = stub(:collection => @collection, :attributes => {})
    end

    it "saves the document" do
      @collection.expects(:save).with(@document.attributes)
      Mongoid::Commands::QuickSave.execute(@document)
    end

    it "returns true" do
      @collection.expects(:save).with(@document.attributes)
      Mongoid::Commands::QuickSave.execute(@document)
    end

  end

end
