require "spec_helper"

describe Mongoid::Persistence::RemoveEmbedded do

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

  let(:location) do
    Location.new(:name => "Home")
  end

  before do
    document.stubs(:collection).returns(collection)
  end

  describe "#persist" do

    def deep_pull_expectation
      lambda {
        collection.expects(:update).with(
          { "_id" => document.id, "addresses._id" => address.id },
          { "$pull" => { "addresses.0.locations" => { "_id" => location.id } } },
          :multi => false,
          :safe => false
        ).returns("Object")
      }
    end

    def root_pull_expectation
      lambda {
        collection.expects(:update).with(
          { "_id" => document.id },
          { "$pull" => { "addresses" => { "_id" => address.id } } },
          :multi => false,
          :safe => false
        ).returns("Object")
      }
    end

    def root_unset_expectation
      lambda {
        collection.expects(:update).with(
          { "_id" => document.id },
          { "$unset" => { "email" => true } },
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
        address.locations << location
        document.addresses << address
      end

      context "when the parent is new" do

        let(:remove) do
          Mongoid::Persistence::RemoveEmbedded.new(address)
        end

        it "notifies its changes to the parent and removes the document" do
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

        it "performs a $pull on the embedded array" do
          root_pull_expectation.call
          remove.persist.should == true
        end
      end

      context "when embedded multiple levels" do

        let(:remove) do
          Mongoid::Persistence::RemoveEmbedded.new(location)
        end

        before do
          document.instance_variable_set(:@new_record, false)
          address.instance_variable_set(:@new_record, false)
        end

        it "performs a $pull on the embedded array" do
          deep_pull_expectation.call
          remove.persist.should == true
        end
      end
    end
  end
end
