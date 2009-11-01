require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

class Person < Mongoid::Document
  field :terms, :type => Boolean
  field :age, :type => Integer, :default => 100
end

describe Mongoid::Attributes do

  describe "#process" do

    context "when supplied hash has values" do

      before do
        @attributes = {
          :_id => "1",
          :title => "value",
          :age => "30",
          :terms => "true",
          :name => {
            :_id => "2", :first_name => "Test", :last_name => "User"
          },
          :addresses => [
            { :_id => "3", :street => "First Street" },
            { :_id => "4", :street => "Second Street" }
          ]
        }
      end

      it "returns a properly cast the attributes" do
        attrs = Person.new(@attributes).attributes
        attrs[:age].should == 30
        attrs[:terms].should == true
      end

    end

  end

end
