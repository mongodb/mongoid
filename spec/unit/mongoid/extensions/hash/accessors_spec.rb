require File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb")

describe Mongoid::Extensions::Hash::Accessors do

  describe "#insert" do

    before do
      @hash = {
        :_id => 1,
        :title => "value",
        :name => {
          :_id => 2, :first_name => "Test", :last_name => "User"
        },
        :addresses => [
          { :_id => 3, :street => "First Street" },
          { :_id => 4, :street => "Second Street" }
        ]
      }
    end

    context "when writing a single attribute" do

      context "when attribute exists" do

        before do
          @new = { :_id => 2, :first_name => "Test2", :last_name => "User2" }
        end

        it "updates the existing attribute" do
          @hash.insert(:name, @new)
          @hash[:name].should == @new
        end

      end

      context "when attribute does not exist" do

        before do
          @hash.delete(:name)
          @new = { :_id => 2, :first_name => "Test2", :last_name => "User2" }
        end

        it "updates the existing attribute" do
          @hash.insert(:name, @new)
          @hash[:name].should == @new
        end

      end

    end

    context "when writing to an array of attributes" do

      context "when matching attribute exists" do

        before do
          @new = { :_id => 3, :street => "New Street" }
        end

        it "updates the matching attributes" do
          @hash.insert(:addresses, @new)
          @hash[:addresses].should include({:street => "New Street", :_id => 3})
        end

      end

      context "when matching attribute does not exist" do

        before do
          @new = { :_id => 10, :street => "New Street" }
        end

        it "updates the matching attributes" do
          @hash.insert(:addresses, @new)
          @hash[:addresses].should == [
            { :_id => 3, :street => "First Street" },
            { :_id => 4, :street => "Second Street" },
            { :_id => 10, :street => "New Street" }
          ]
        end
      end

    end

  end

end
