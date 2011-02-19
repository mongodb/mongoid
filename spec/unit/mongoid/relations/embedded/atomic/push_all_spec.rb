require "spec_helper"

describe Mongoid::Relations::Embedded::Atomic::PushAll do

  describe "#consume" do

    context "when consuming $pushAll operations" do

      context "when there is no existing operation" do

        let(:push_all) do
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
          push_all.consume(selector, operations, options)
        end

        it "push alls the selector" do
          push_all.selector.should == selector
        end

        it "push alls the $pushAll operations" do
          push_all.operations.should ==
            { "$pushAll" => { "addresses" => [{ "_id" => "street" }] } }
        end

        it "push alls the options" do
          push_all.options.should == options
        end
      end

      context "when there is an existing operation" do

        let(:push_all) do
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
          push_all.consume(selector, operations_one, options)
          push_all.consume(selector, operations_two, options)
        end

        it "push alls the selector" do
          push_all.selector.should == selector
        end

        it "push alls the $pushAll operations" do
          push_all.operations.should ==
            { "$pushAll" => {
                "addresses" => [{ "_id" => "bond-street" }, { "_id" => "high-street" }]
              }
            }
        end

        it "push alls the options" do
          push_all.options.should == options
        end
      end
    end

    context "when consuming $push operations" do

      context "when there is no existing operation" do

        let(:push_all) do
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
          push_all.consume(selector, operations, options)
        end

        it "push alls the selector" do
          push_all.selector.should == selector
        end

        it "push alls the $push operations" do
          push_all.operations.should ==
            { "$pushAll" => { "addresses" => [{ "_id" => "street" }] } }
        end

        it "push alls the options" do
          push_all.options.should == options
        end
      end

      context "when there is an existing operation" do

        let(:push_all) do
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
          push_all.consume(selector, operations_one, options)
          push_all.consume(selector, operations_two, options)
        end

        it "push alls the selector" do
          push_all.selector.should == selector
        end

        it "push alls the $push operations" do
          push_all.operations.should ==
            { "$pushAll" => {
                "addresses" => [{ "_id" => "bond-street" }, { "_id" => "high-street" }]
              }
            }
        end

        it "push alls the options" do
          push_all.options.should == options
        end
      end
    end
  end
end
