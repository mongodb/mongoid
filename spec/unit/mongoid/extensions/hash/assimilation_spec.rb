require "spec_helper"

describe Mongoid::Extensions::Hash::Assimilation do

  describe "#assimilate" do

    before do
      @child = { :first_name => "Hank", :last_name => "Moody" }
      @parent = Person.new(:title => "Mr.")
      @options = Mongoid::Associations::Options.new(:name => :name)
    end

    it "incorporates the hash into the object graph" do
      @child.assimilate(@parent, @options)
      @parent.name.first_name.should == "Hank"
      @parent.name.last_name.should == "Moody"
    end

  end

end
