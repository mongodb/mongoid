require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

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
        @fields = Person.fields.values
      end

      it "returns a properly cast HashWithIndifferentAccess" do
        attrs = Person.new(@attributes).attributes
        attrs[:age].should == 30
        attrs[:terms].should == true
      end

    end

  end

end
