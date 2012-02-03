require "spec_helper"

describe Mongoid::Persistence::Operations::Embedded::Insert do

  let(:document) do
    Patient.new(title: "Mr")
  end

  let(:address) do
    Address.new(street: "Oxford St")
  end

  let(:collection) do
    stub.quacks_like(Moped::Collection.allocate)
  end

  let(:email) do
    Email.new(address: "test@example.com")
  end

  before do
    document.stubs(:collection).returns(collection)
  end

  let(:query) do
    stub
  end

  before(:all) do
    Mongoid.identity_map_enabled = true
  end

  after(:all) do
    Mongoid.identity_map_enabled = false
  end

  describe "#persist" do

    context "when the insert succeeded" do

      let(:person) do
        Person.create
      end

      let(:address) do
        person.addresses.create(street: "Hobrechtstr")
      end

      let(:in_map) do
        Mongoid::IdentityMap.get(Address, address.id)
      end

      it "does not put the document in the identity map" do
        in_map.should be_nil
      end
    end

    context "when no parent is set" do

      let(:address) do
        Address.new
      end

      let(:insert) do
        described_class.new(address)
      end

      it "raises an error" do
        expect {
          insert.persist
        }.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    def root_insert_expectation
      ->{
        collection.expects(:insert).with(
          document.raw_attributes
        ).returns("Object")
      }
    end

    def root_push_expectation
      ->{
        collection.expects(:find).with({ "_id" => document.id }).returns(query)
        query.expects(:update).with(
          { "$push" => { "addresses" => address.raw_attributes }}
        ).returns("Object")
      }
    end

    def root_set_expectation
      ->{
        collection.expects(:find).with({ "_id" => document.id }).returns(query)
        query.expects(:update).with(
          { "$set" => { "email" => email.raw_attributes } }
        ).returns("Object")
      }
    end

    context "when the embedded document is an embeds_one" do

      before do
        document.email = email
      end

      context "when the parent is new" do

        let(:insert) do
          described_class.new(email)
        end

        it "notifies its changes to parent and inserts the parent" do
          root_insert_expectation.call
          insert.persist.should eq(email)
        end
      end

      context "when the parent is not new" do

        let(:insert) do
          described_class.new(email)
        end

        before do
          document.instance_variable_set(:@new_record, false)
        end

        it "performs an in place $set on the embedded document" do
          root_set_expectation.call
          insert.persist.should eq(email)
        end
      end
    end

    context "when the embedded document is an embeds_many" do

      before do
        document.addresses << address
      end

      context "when the parent is new" do

        let(:insert) do
          described_class.new(address)
        end

        it "notifies its changes to the parent and inserts the parent" do
          root_insert_expectation.call
          insert.persist.should eq(address)
        end

        it "sets new_record to false" do
          root_insert_expectation.call
          insert.persist.new_record?.should be_false
        end
      end

      context "when the parent is not new" do

        let(:insert) do
          described_class.new(address)
        end

        before do
          document.instance_variable_set(:@new_record, false)
        end

        it "performs a $push on the embedded array" do
          root_push_expectation.call
          insert.persist.should eq(address)
        end

        context "when we add the parent to the child" do

          let(:other_address) do
            document.addresses.build(street: "Oxford St")
          end

          it "performs a $push on the embedded array" do
            collection.expects(:find).with({ "_id" => document.id }).returns(query)
            query.expects(:update).with(
              { "$push" => { "addresses" => other_address.raw_attributes } }
            ).returns("Object")
            described_class.new(other_address).persist.should eq(other_address)
          end
        end
      end
    end
  end
end
