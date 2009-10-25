require File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb")

describe Mongoid::Extensions::Array::Parentization do

  describe "#parentize" do

    before do
      @parent = stub
      @child = mock
      @array = [@child]
    end

    it "sets the parent on each element" do
      @child.expects(:add_observer).with(@parent)
      @child.expects(:parent=).with(@parent)
      @child.expects(:association_name=).with(:child)
      @array.parentize(@parent, :child)
    end

  end

end
