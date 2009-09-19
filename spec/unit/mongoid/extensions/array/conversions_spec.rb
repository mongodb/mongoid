require File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb")

describe Mongoid::Extensions::Array::Conversions do

  describe "#mongoidize" do

    it "collects each of its attributes" do
      array = [Person.new(:title => "Sir"), Person.new(:title => "Madam")]
      array.mongoidize.should == [{ :title => "Sir" }, { :title => "Madam" }]
    end

  end

end