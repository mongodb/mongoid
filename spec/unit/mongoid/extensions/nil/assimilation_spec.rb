require "spec_helper"

describe Mongoid::Extensions::Nil::Assimilation do

  describe "#assimilate" do

    before do
      @name = Name.new(:first_name => "Durran")
      @parent = Person.new(:title => "Mr.", :name => @name)
      @options = Mongoid::Associations::Options.new(:name => :name)
    end

    it "removes the child attribute from the parent" do
      nil.assimilate(@parent, @options)
      @parent.attributes[:name].should be_nil
    end

    it "returns nil" do
      nil.assimilate(@parent, @options).should be_nil
    end

  end

end
