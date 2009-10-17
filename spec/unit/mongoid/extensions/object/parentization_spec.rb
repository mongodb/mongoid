require File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb")

describe Mongoid::Extensions::Object::Parentization do

  describe "#parentize" do

    before do
      @parent = Person.new
      @child = Name.new
    end

    it "sets the parent on each element" do
      @child.parentize(@parent)
      @child.parent.should == @parent
    end

  end

end