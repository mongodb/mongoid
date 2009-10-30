require File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb")

describe Mongoid::Extensions::Object::Conversions do

  describe "#mongoidize" do

    it "returns its attributes" do
      Person.new(:_id => 1, :title => "Sir").mongoidize.should ==
        HashWithIndifferentAccess.new({ :_id => 1, :title => "Sir", :age => 100 })
    end

  end

end
