require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

class Parent < Mongoloid::Document
end

describe Mongoloid::Association do

  describe "#klass" do

    it "returns the klass supplied in the constructor" do
      association = Mongoloid::Association.new(:has_many, "Parent", Parent.new)
      association.klass.should == "Parent"
    end

  end

  describe "#instance" do

    it "returns the instance supplied in the constructor" do
      instance = Parent.new
      association = Mongoloid::Association.new(:has_many, "Parent", instance)
      association.instance.should == instance
    end

  end

  describe "#new" do

    context "when type is not valid" do

      it "raises an error" do
        lambda { Mongoloid::Association.new(:has_infinite, "Class", nil) }.should raise_error
      end

    end

  end

  describe "#type" do

    it "returns the association type defined in the constructor" do
      association = Mongoloid::Association.new(:has_many, "Parent", Parent.new)
      association.type.should == :has_many
    end

  end

end