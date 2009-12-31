require "spec_helper"

describe Mongoid::Commands::Delete do

  describe "#execute" do

    before do
      @collection = mock
      @document = stub(:collection => @collection, :id => "1", :_parent => false)
    end

    it "removes the document from its collection" do
      @collection.expects(:remove).with({ :_id => @document.id })
      Mongoid::Commands::Delete.execute(@document)
    end

    context "when the document is embedded" do

      before do
        @parent = Person.new
        @address = Address.new(:street => "Genoa Pl")
        @parent.addresses << @address
      end

      it "removes the document from the parent attributes" do
        @parent.addresses.should == [@address]
        Mongoid::Commands::Delete.execute(@address)
        @parent.addresses.should be_empty
      end

    end

  end

end
