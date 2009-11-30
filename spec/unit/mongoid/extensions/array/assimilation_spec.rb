require "spec_helper"

describe Mongoid::Extensions::Array::Assimilation do

  describe "#assimilate" do

    before do
      @address_one = { :street => "Circular Quay" }
      @address_two = Address.new(:street => "King St.")
      @parent = Person.new(:title => "Mr.")
      @options = Mongoid::Associations::Options.new(:name => :addresses)
      @child = [@address_one, @address_two]
    end

    it "incorporates the hash into the object graph" do
      @child.assimilate(@parent, @options)
      @parent.addresses.size.should == 2
      @parent.addresses.first.street.should == "Circular Quay"
      @parent.addresses.last.street.should == "King St."
    end

  end

end
