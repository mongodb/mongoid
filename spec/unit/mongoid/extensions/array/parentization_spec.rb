require File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb")

describe Mongoid::Extensions::Array::Parentization do

  describe "#parentize" do

    before do
      @parent = stub
      @child = mock
      @array = [@child]
    end

    it "sets the parent on each element" do
      @parent.expects(:add_observer).with(@child)
      @child.expects(:parent=).with(@parent)
      @array.parentize(@parent)
    end

  end

end