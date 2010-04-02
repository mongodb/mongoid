require "spec_helper"

describe Mongoid::Persistence::Remove do

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

    def root_set_expectation
      lambda {
        collection.expects(:update).with(
          { "_id" => document.id },
          { "$set" => { "addresses" => [] } },
          :multi => false,
          :safe => true
        ).returns("Object")
      }
    end

    def root_unset_expectation
      lambda {
        collection.expects(:update).with(
          { "_id" => document.id },
          { "$unset" => { "email" => true } },
          :multi => false,
          :safe => true
        ).returns("Object")
      }
    end

    context "when the embedded document is an embeds_one" do

      before do
        document.email = email
      end

      context "when the parent is new" do

        let(:remove) do
          Mongoid::Persistence::RemoveEmbedded.new(email)
        end

        it "notifies its changes to parent and removes the parent" do
          remove.persist.should == true
          document.email.should be_nil
        end
      end

      context "when the parent is not new" do

        let(:remove) do
          Mongoid::Persistence::RemoveEmbedded.new(email)
        end

        before do
          document.instance_variable_set(:@new_record, false)
        end

        it "performs an in place $set on the embedded document" do
          root_unset_expectation.call
          remove.persist.should == true
        end
      end
    end

    context "when the embedded document is an embeds_many" do

      before do
        document.addresses << address
      end

      context "when the parent is new" do

        let(:remove) do
          Mongoid::Persistence::RemoveEmbedded.new(address)
        end

        it "notifies its changes to the parent and removes the parent" do
          remove.persist.should == true
          document.addresses.should == []
        end
      end

      context "when the parent is not new" do

        let(:remove) do
          Mongoid::Persistence::RemoveEmbedded.new(address)
        end

        before do
          document.instance_variable_set(:@new_record, false)
        end

        it "performs a $push on the embedded array" do
          root_set_expectation.call
          remove.persist.should == true
        end
      end
    end
  end
end
