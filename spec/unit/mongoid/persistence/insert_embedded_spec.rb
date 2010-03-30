require "spec_helper"

describe Mongoid::Persistence::Insert do

  let(:document) do
    Patient.new(:title => "Mr")
  end

  let(:address) do
    Address.new(:street => "Oxford St")
  end

  let(:collection) do
    stub.quacks_like(Mongoid::Collection.allocate)
  end

  before do
    document.stubs(:collection).returns(collection)
  end

  describe "#persist" do

    def root_set_expectation
      lambda {
        collection.expects(:insert).with(
          document.raw_attributes,
          :safe => true
        ).returns("Object")
      }
    end

    def root_push_expectation
      lambda {
        collection.expects(:update).with(
          { "_id" => document.id },
          { "addresses" => { "$push" => address.raw_attributes } },
          :safe => true
        ).returns("Object")
      }
    end

    context "when the embedded document is an embeds_one" do

      context "when the parent is new" do

        it "notifies its changes to parent and inserts the parent"

      end

      context "when the parent is not new" do

        it "performs an in place $set on the embedded document"
      end
    end

    context "when the embedded document is an embeds_many" do

      before do
        document.addresses << address
      end

      context "when the parent is new" do

        let(:insert) do
          Mongoid::Persistence::InsertEmbedded.new(address)
        end

        it "notifies its changes to the parent and inserts the parent" do
          root_set_expectation.call
          insert.persist.should == address
        end
      end

      context "when the parent is not new" do

        let(:insert) do
          Mongoid::Persistence::InsertEmbedded.new(address)
        end

        before do
          document.instance_variable_set(:@new_record, false)
        end

        it "performs a $push on the embedded array" do
          root_push_expectation.call
          insert.persist.should == address
        end
      end
    end
  end
end
