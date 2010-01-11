require "spec_helper"

describe Mongoid::Commands::Save do

  describe "#execute" do

    before do
      @parent_collection = stub(:save => true)
      @doc_collection = stub(:save => true)
      @parent = stub(:collection => @parent_collection,
                     :valid? => true,
                     :run_callbacks => true,
                     :_parent => nil,
                     :attributes => {},
                     :new_record= => false)
      @document = stub(:collection => @doc_collection,
                       :run_callbacks => true,
                       :_parent => @parent,
                       :attributes => {},
                       :new_record= => false)
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

      it "returns true" do
        Mongoid::Commands::Save.execute(@document).should be_true
      end

      context "when the document has a parent" do

        it "executes a save on the parent" do
          @parent_collection.expects(:save).with(@parent.attributes)
          Mongoid::Commands::Save.execute(@document)
        end

      end

      context "when the document has no parent" do

        before do
          @document.expects(:_parent).returns(nil)
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

    context "when saving without validation" do

      before do
        @document.stubs(:valid?).returns(false)
      end

      it "ignores validation and returns true" do
        Mongoid::Commands::Save.execute(@document, false).should be_true
      end

    end

  end

  context "when the document is embedded" do

    before do
      @child_name = Name.new(:first_name => "Testy")
    end

    context "when parent reference does not exist" do

      it "raises an error" do
        lambda { @child_name.save }.should raise_error
      end

    end

  end

end
