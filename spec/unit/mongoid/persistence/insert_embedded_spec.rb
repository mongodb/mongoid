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

  let(:email) do
    Email.new(:address => "test@example.com")
  end

  before do
    document.stubs(:collection).returns(collection)
  end

  describe "#persist" do

    def root_insert_expectation
      lambda {
        collection.expects(:insert).with(
          document.raw_attributes,
          :safe => false
        ).returns("Object")
      }
    end

    def root_push_expectation
      lambda {
        collection.expects(:update).with(
          { "_id" => document.id },
          { "$push" => { "addresses" => address.raw_attributes } },
          :multi => false,
          :safe => false
        ).returns("Object")
      }
    end

    def root_set_expectation
      lambda {
        collection.expects(:update).with(
          { "_id" => document.id },
          { "$set" => { "email" => email.raw_attributes } },
          :multi => false,
          :safe => false
        ).returns("Object")
      }
    end

    context "when the embedded document is an embeds_one" do

      before do
        document.email = email
      end

      context "when the parent is new" do

        let(:insert) do
          Mongoid::Persistence::InsertEmbedded.new(email)
        end

        it "notifies its changes to parent and inserts the parent" do
          root_insert_expectation.call
          insert.persist.should == email
        end
      end

      context "when the parent is not new" do

        let(:insert) do
          Mongoid::Persistence::InsertEmbedded.new(email)
        end

        before do
          document.instance_variable_set(:@new_record, false)
        end

        it "performs an in place $set on the embedded document" do
          root_set_expectation.call
          insert.persist.should == email
        end

        it "sets new_record to false" do
          root_set_expectation.call
          insert.persist.new_record?.should be_false
        end
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
          root_insert_expectation.call
          insert.persist.should == address
        end

        it "sets new_record to false" do
          root_insert_expectation.call
          insert.persist.new_record?.should be_false
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

        context "when we add the parent to the child" do

          let(:other_address) do
            document.addresses.build(:street => "Oxford St")
          end

          it "performs a $push on the embedded array" do
            collection.expects(:update).with(
              { "_id" => document.id },
              { "$push" => { "addresses" => other_address.raw_attributes } },
              :multi => false,
              :safe => false
            ).returns("Object")
            Mongoid::Persistence::InsertEmbedded.new(other_address).persist.should == other_address
          end
        end
      end
    end
  end
end
