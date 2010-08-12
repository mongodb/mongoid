require "spec_helper"

describe Mongoid::MultiParameterAttributes do
  describe "#process" do
    context "creating a post" do
      before do
        @post = Post.new({
          "created_at(1i)" => 2010,
          "created_at(2i)" => 8,
          "created_at(3i)" => 12,
          "created_at(4i)" => 15,
          "created_at(5i)" => 45
        })
      end
      
      it "should set a multi-parameter Time attribute correctly" do
        @post.created_at.should == Time.local(2010, 8, 12, 15, 45)
      end
      
      it "should not leave ugly attributes on the model" do
        @post.attributes.should_not have_key("created_at(1i)")
      end
    end
    
    context "creating a person" do
      before do
        @person = Person.new({
          "dob(1i)" => 1980,
          "dob(2i)" => 7,
          "dob(3i)" => 27
        })
      end

      it "should set a multi-parameter Date attribute correctly" do
        @person.dob.should == Date.civil(1980, 7, 27)
      end
      
    end
    
  end
end