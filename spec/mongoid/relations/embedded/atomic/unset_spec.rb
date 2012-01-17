require "spec_helper"

describe Mongoid::Relations::Embedded::Atomic::Unset do

  describe "#consume" do

    context "when consuming $pullAll operations" do

      context "when there is no existing operation" do

        let(:unset) do
          described_class.new
        end

        let(:selector) do
          { :_id => BSON::ObjectId.new }
        end

        let(:operations) do
          { "$pullAll" => { "addresses" => [{ "_id" => "street" }] } }
        end

        let(:options) do
          { :safe => true, :multi => false }
        end

        before do
          unset.consume(selector, operations, options)
        end

        it "unsets the selector" do
          unset.selector.should == selector
        end

        it "unsets the $unset operations" do
          unset.operations.should ==
            { "$unset" => { "addresses" => true } }
        end

        it "unsets the options" do
          unset.options.should == options
        end
      end

      context "when there is an existing operation" do

        let(:unset) do
          described_class.new
        end

        let(:selector) do
          { :_id => BSON::ObjectId.new }
        end

        let(:operations_one) do
          { "$pullAll" => { "addresses" => [{ "_id" => "bond-street" }] } }
        end

        let(:operations_two) do
          { "$pullAll" => { "addresses" => [{ "_id" => "high-street" }] } }
        end

        let(:options) do
          { :safe => true, :multi => false }
        end

        before do
          unset.consume(selector, operations_one, options)
          unset.consume(selector, operations_two, options)
        end

        it "unsets the selector" do
          unset.selector.should == selector
        end

        it "unsets the $unset operations" do
          unset.operations.should ==
            { "$unset" => { "addresses" => true } }
        end

        it "unsets the options" do
          unset.options.should == options
        end
      end
    end

    context "when consuming $pull operations" do

      context "when there is no existing operation" do

        let(:unset) do
          described_class.new
        end

        let(:selector) do
          { :_id => BSON::ObjectId.new }
        end

        let(:operations) do
          { "$pull" => { "addresses" => { "_id" => "street" } } }
        end

        let(:options) do
          { :safe => true, :multi => false }
        end

        before do
          unset.consume(selector, operations, options)
        end

        it "unsets the selector" do
          unset.selector.should == selector
        end

        it "unsets the $unset operations" do
          unset.operations.should ==
            { "$unset" => { "addresses" => true } }
        end

        it "unsets the options" do
          unset.options.should == options
        end
      end

      context "when there is an existing operation" do

        let(:unset) do
          described_class.new
        end

        let(:selector) do
          { :_id => BSON::ObjectId.new }
        end

        let(:operations_one) do
          { "$pull" => { "addresses" => { "_id" => "bond-street" } } }
        end

        let(:operations_two) do
          { "$pull" => { "addresses" => { "_id" => "high-street" } } }
        end

        let(:options) do
          { :safe => true, :multi => false }
        end

        before do
          unset.consume(selector, operations_one, options)
          unset.consume(selector, operations_two, options)
        end

        it "unsets the selector" do
          unset.selector.should == selector
        end

        it "unsets the $unset operations" do
          unset.operations.should ==
            { "$unset" => { "addresses" => true } }
        end

        it "unsets the options" do
          unset.options.should == options
        end
      end
    end
  end
end

