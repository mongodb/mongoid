require "spec_helper"

describe Mongoid::Persistence::Operations::Update do

  let(:document) do
    Patient.instantiate("_id" => BSON::ObjectId.new)
  end

  let(:address) do
    Address.instantiate("_id" => "oxford-st", "street" => "Oxford St")
  end

  let(:root_category) do
    RootCategory.instantiate("_id" => BSON::ObjectId.new.to_s)
  end

  let(:category) do
    Category.instantiate("_id" => BSON::ObjectId.new.to_s, "name" => 'Programming')
  end

  let(:collection) do
    stub.quacks_like(Moped::Collection.allocate)
  end

  let(:query) do
    stub
  end

  before do
    document.stubs(:collection).returns(collection)
    root_category.stubs(:collection).returns(collection)
  end

  describe "#initialize" do

    let(:update) do
      described_class.new(document)
    end

    it "sets the document" do
      update.document.should eq(document)
    end

    it "sets the collection" do
      update.collection.should eq(document.collection)
    end

    it "defaults validation to true" do
      update.should be_validating
    end
  end

  describe "#persist" do

    def root_set_expectation
      ->{
        collection.expects(:find).with({ "_id" => document.id }).returns(query)
        query.expects(:update).with({ "$set" => document.setters }).returns("Object")
      }
    end

    def embedded_set_expectation
      ->{
        collection.expects(:find).with(
          { "_id" => document.id, "addresses._id" => address.id }
        ).returns(query)
        query.expects(:update).with({ "$set" => address.setters }).returns("Object")
      }
    end

    let(:update) do
      described_class.new(document)
    end

    context "when the document is changed" do

      before do
        document.title = "Sir"
      end

      context "when the document is valid" do

        it "performs a $set for changed fields" do
          root_set_expectation.call
          update.persist.should be_true
        end

        it "moves the changed fields to previously changed" do
          root_set_expectation.call
          update.persist
          document.changed?.should be_false
        end

      end

      context "when the document is not valid" do

        before do
          document.stubs(:valid?).returns(false)
        end

        it "returns false" do
          update.persist.should be_false
        end
      end

      context "when not validating" do

        before do
          update.instance_variable_set(:@validating, false)
        end

        after do
          update.instance_variable_set(:@validating, true)
        end

        it "updates the document in the database" do
          root_set_expectation.call
          update.persist.should be_true
        end
      end

      context "when the document is embedded" do

        let(:embedded) do
          described_class.new(address)
        end

        before do
          document.addresses << address
          address.city = "London"
        end

        it "performs a $set for the embedded changed fields" do
          embedded_set_expectation.call
          embedded.persist
        end
      end
    end
  end
end
