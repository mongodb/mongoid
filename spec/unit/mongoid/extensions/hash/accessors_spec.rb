require "spec_helper"

describe Mongoid::Extensions::Hash::Accessors do

  before do
    @hash = {
      :_id => 1,
      :title => "value",
      :name => {
        :_id => 2, :first_name => "Test", :last_name => "User"
      },
      :pet => {
        :_id => 6,
        :name => "Fido",
        :vet_visits => [ { :date => Date.new(2007, 1, 1) } ]
      },
      :addresses => [
        { :_id => 3, :street => "First Street" },
        { :_id => 4, :street => "Second Street" }
      ]
    }
  end

  describe "#remove" do

    context "when removing from an array" do

      context "when the elements exist" do

        it "removes the element from the array" do
          @hash.remove(:addresses, { :_id => 3, :street => "First Street" })
          @hash[:addresses].size.should == 1
        end

      end

      context "when the elements do not exist" do

        it "does not raise an error" do
          @hash.remove(:aliases, { :_id => 3, :street => "First Street" })
        end

      end

    end

    context "when removing a single object" do

      context "when the element exists" do

        it "removes the element from the array" do
          @hash.remove(:name, { :_id => 2, :first_name => "Test", :last_name => "User" })
          @hash[:name].should be_nil
        end

      end

      context "when the element does not exist" do

        it "does not raise an error" do
          @hash.remove(:alias, { :_id => 3, :street => "First Street" })
        end

      end

    end

  end

  describe "#insert" do

    context "when writing to a hash with a child array" do

      context "when child attributes not present" do

        it "does nothing to the children" do
          @hash.insert(:pet, { :name => "Bingo" })
          @hash[:pet].should == {
            :_id => 6,
            :name => "Bingo",
            :vet_visits => [ { :date => Date.new(2007, 1, 1) } ]
          }
        end

      end

      context "when child attributes present" do

        it "overwrites the child attributes" do
          @hash.insert(:pet, { :vet_visits => [ { :date => Date.new(2009, 11, 11) } ] })
          @hash[:pet][:vet_visits].should == [ { :date => Date.new(2009, 11, 11) } ]
        end

      end

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

        it "adds the new attribute" do
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
