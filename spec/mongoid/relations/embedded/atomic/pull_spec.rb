require "spec_helper"

describe Mongoid::Relations::Embedded::Atomic::Pull do

  describe "#consume" do

    context "when consuming $pullAll operations" do

      context "when there is no existing operation" do

        let(:pull) do
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
          pull.consume(selector, operations, options)
        end

        it "pulls the selector" do
          pull.selector.should == selector
        end

        it "pulls the $pullAll operations" do
          pull.operations.should ==
            { "$pull" =>
              { "addresses" =>
                { "_id" => { "$in" => [ "street" ] } }
              }
            }
        end

        it "pulls the options" do
          pull.options.should == options
        end
      end

      context "when there is an existing operation" do

        let(:pull) do
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
          pull.consume(selector, operations_one, options)
          pull.consume(selector, operations_two, options)
        end

        it "pulls the selector" do
          pull.selector.should == selector
        end

        it "pulls the $pullAll operations" do
          pull.operations.should ==
            { "$pull" =>
              { "addresses" =>
                { "_id" => { "$in" => [ "bond-street", "high-street" ] } }
              }
            }
        end

        it "pulls the options" do
          pull.options.should == options
        end
      end
    end

    context "when consuming $pull operations" do

      context "when there is no existing operation" do

        let(:pull) do
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
          pull.consume(selector, operations, options)
        end

        it "pulls the selector" do
          pull.selector.should == selector
        end

        it "pulls the $pull operations" do
          pull.operations.should ==
            { "$pull" =>
              { "addresses" =>
                { "_id" => { "$in" => [ "street" ] } }
              }
            }
        end

        it "pulls the options" do
          pull.options.should == options
        end
      end

      context "when there is an existing operation" do

        let(:pull) do
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
          pull.consume(selector, operations_one, options)
          pull.consume(selector, operations_two, options)
        end

        it "pulls the selector" do
          pull.selector.should == selector
        end

        it "pulls the $pull operations" do
          pull.operations.should ==
            { "$pull" =>
              { "addresses" =>
                { "_id" => { "$in" => [ "bond-street", "high-street" ] } }
              }
            }
        end

        it "pulls the options" do
          pull.options.should == options
        end
      end
    end
  end
end
