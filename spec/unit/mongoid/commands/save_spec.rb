require File.expand_path(File.join(File.dirname(__FILE__), "/../../../spec_helper.rb"))

describe Mongoid::Commands::Save do

  describe "#execute" do

    before do
      @parent_collection = stub(:save)
      @doc_collection = stub(:save)
      @parent = stub(:collection => @parent_collection,
                     :valid? => true,
                     :run_callbacks => true,
                     :parent => nil,
                     :attributes => {})
      @document = stub(:collection => @doc_collection,
                       :run_callbacks => true,
                       :parent => @parent,
                       :attributes => {})
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

      it "returns the document" do
        Mongoid::Commands::Save.execute(@document).should == @document
      end

      context "when the document has a parent" do

        it "executes a save on the parent" do
          @parent_collection.expects(:save).with(@parent.attributes)
          Mongoid::Commands::Save.execute(@document)
        end

      end

      context "when the document has no parent" do

        before do
          @document.expects(:parent).returns(nil)
        end

        it "calls save on the document collection" do
          @doc_collection.expects(:save).with(@document.attributes)
          Mongoid::Commands::Save.execute(@document)
        end

      end

    end

    context "when document is invalid" do

      before do
        @document.expects(:valid?).returns(false)
      end

      it "returns false" do
        Mongoid::Commands::Save.execute(@document).should be_false
      end

    end

  end

end
