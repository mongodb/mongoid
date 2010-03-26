require "spec_helper"

describe Mongoid::Persistence::Update do

  let(:document) do
    Patient.new(:_id => Mongo::ObjectID.new.to_s)
  end

  let(:collection) do
    stub.quacks_like(Mongoid::Collection.allocate)
  end

  before do
    document.stubs(:collection).returns(collection)
  end

  describe "#initialize" do

    let(:update) do
      Mongoid::Persistence::Update.new(document)
    end

    it "sets the document" do
      update.document.should == document
    end

    it "sets the collection" do
      update.collection.should == document.collection
    end

    it "defaults validation to true" do
      update.validate.should == true
    end

    it "sets the options" do
      update.options.should ==
        { :multi => false, :safe => Mongoid.persist_in_safe_mode }
    end
  end

  describe "#persist" do

    def mongo_expects
      lambda {
        collection.expects(:update).with(
          { "_id" => document.id },
          { "$set" => document.new_values },
          :multi => false,
          :safe => true
        ).returns("Object")
      }
    end

    let(:update) do
      Mongoid::Persistence::Update.new(document)
    end

    context "when the document is changed" do

      before do
        document.title = "Sir"
      end

      context "when the document is valid" do

        it "performs a $set for changed fields" do
          mongo_expects.call
          update.persist.should == true
        end

        it "moves the changed fields to previously changed" do
          mongo_expects.call
          update.persist
          document.changed?.should == false
        end

      end

      context "when the document is not valid" do

        before do
          document.stubs(:valid?).returns(false)
        end

        it "returns false" do
          update.persist.should == false
        end
      end

      context "when not validating" do

        before do
          update.instance_variable_set(:@validate, false)
          document.stubs(:valid?).returns(false)
        end

        after do
          update.instance_variable_set(:@validate, true)
        end

        it "updates the document in the database" do
          mongo_expects.call
          update.persist.should == true
        end
      end
    end

    context "when the document is not changed" do

      it "returns true" do
        update.persist.should == true
      end
    end
  end
end
