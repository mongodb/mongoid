require "spec_helper"

describe Mongoid::Relations::Embedded::Atomic::Set do

  describe "#consume" do

    context "when consuming $pushAll operations" do

      context "when there is no existing operation" do

        let(:set) do
          described_class.new
        end

        let(:selector) do
          { :_id => BSON::ObjectId.new }
        end

        let(:operations) do
          { "$pushAll" => { "addresses" => [{ "_id" => "street" }] } }
        end

        let(:options) do
          { :safe => true, :multi => false }
        end

        before do
          set.consume(selector, operations, options)
        end

        it "sets the selector" do
          set.selector.should == selector
        end

        it "sets the $set operations" do
          set.operations.should ==
            { "$set" => { "addresses" => [{ "_id" => "street" }] } }
        end

        it "sets the options" do
          set.options.should == options
        end
      end

      context "when there is an existing operation" do

        let(:set) do
          described_class.new
        end

        let(:selector) do
          { :_id => BSON::ObjectId.new }
        end

        let(:operations_one) do
          { "$pushAll" => { "addresses" => [{ "_id" => "bond-street" }] } }
        end

        let(:operations_two) do
          { "$pushAll" => { "addresses" => [{ "_id" => "high-street" }] } }
        end

        let(:options) do
          { :safe => true, :multi => false }
        end

        before do
          set.consume(selector, operations_one, options)
          set.consume(selector, operations_two, options)
        end

        it "sets the selector" do
          set.selector.should == selector
        end

        it "sets the $set operations" do
          set.operations.should ==
            { "$set" => {
                "addresses" => [{ "_id" => "bond-street" }, { "_id" => "high-street" }]
              }
            }
        end

        it "sets the options" do
          set.options.should == options
        end
      end
    end

    context "when consuming $push operations" do

      context "when there is no existing operation" do

        let(:set) do
          described_class.new
        end

        let(:selector) do
          { :_id => BSON::ObjectId.new }
        end

        let(:operations) do
          { "$push" => { "addresses" => { "_id" => "street" } } }
        end

        let(:options) do
          { :safe => true, :multi => false }
        end

        before do
          set.consume(selector, operations, options)
        end

        it "sets the selector" do
          set.selector.should == selector
        end

        it "sets the $set operations" do
          set.operations.should ==
            { "$set" => { "addresses" => [{ "_id" => "street" }] } }
        end

        it "sets the options" do
          set.options.should == options
        end
      end

      context "when there is an existing operation" do

        let(:set) do
          described_class.new
        end

        let(:selector) do
          { :_id => BSON::ObjectId.new }
        end

        let(:operations_one) do
          { "$push" => { "addresses" => { "_id" => "bond-street" } } }
        end

        let(:operations_two) do
          { "$push" => { "addresses" => { "_id" => "high-street" } } }
        end

        let(:options) do
          { :safe => true, :multi => false }
        end

        before do
          set.consume(selector, operations_one, options)
          set.consume(selector, operations_two, options)
        end

        it "sets the selector" do
          set.selector.should == selector
        end

        it "sets the $set operations" do
          set.operations.should ==
            { "$set" => {
                "addresses" => [{ "_id" => "bond-street" }, { "_id" => "high-street" }]
              }
            }
        end

        it "sets the options" do
          set.options.should == options
        end
      end
    end

    context "when consuming $set operations" do

      context "when there is no existing operation" do

        let(:set) do
          described_class.new
        end

        let(:selector) do
          { :_id => BSON::ObjectId.new }
        end

        let(:operations) do
          { "$set" => { "addresses" => [{ "_id" => "street" }] } }
        end

        let(:options) do
          { :safe => true, :multi => false }
        end

        before do
          set.consume(selector, operations, options)
        end

        it "sets the selector" do
          set.selector.should == selector
        end

        it "sets the $set operations" do
          set.operations.should ==
            { "$set" => { "addresses" => [{ "_id" => "street" }] } }
        end

        it "sets the options" do
          set.options.should == options
        end
      end

      context "when there is an existing operation" do

        let(:set) do
          described_class.new
        end

        let(:selector) do
          { :_id => BSON::ObjectId.new }
        end

        let(:operations_one) do
          { "$set" => { "addresses" => [{ "_id" => "bond-street" }] } }
        end

        let(:operations_two) do
          { "$set" => { "addresses" => [{ "_id" => "high-street" }] } }
        end

        let(:options) do
          { :safe => true, :multi => false }
        end

        before do
          set.consume(selector, operations_one, options)
          set.consume(selector, operations_two, options)
        end

        it "replaces the selector" do
          set.selector.should == selector
        end

        it "replaces the $set operations" do
          set.operations.should ==
            { "$set" => {
                "addresses" => [{ "_id" => "high-street" }]
              }
            }
        end

        it "replaces the options" do
          set.options.should == options
        end
      end
    end
  end
end
