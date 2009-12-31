require "spec_helper"

describe Mongoid::Commands::Destroy do

  describe "#execute" do

    before do
      @collection = stub_everything
      @document = stub(:run_callbacks => true,
                       :collection => @collection,
                       :id => "1",
                       :_parent => false)
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

    context "when the document is embedded" do

      before do
        @parent = Person.new
        @address = Address.new(:street => "Genoa Pl")
        @parent.addresses << @address
      end

      it "removes the document from the parent attributes" do
        @parent.addresses.should == [@address]
        Mongoid::Commands::Destroy.execute(@address)
        @parent.addresses.should be_empty
      end

    end

  end

end
