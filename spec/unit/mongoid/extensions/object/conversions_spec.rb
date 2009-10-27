require File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb")

describe Mongoid::Extensions::Object::Conversions do

  describe "#mongoidize" do

    it "returns its attributes" do
      Person.new(:title => "Sir").mongoidize.should ==
        HashWithIndifferentAccess.new({ :title => "Sir" })
    end

  end

end
