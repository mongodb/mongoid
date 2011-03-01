require "spec_helper"

describe Mongoid::Collections::Master do

  let(:collection) do
    stub.quacks_like(Mongo::Collection.allocate)
  end

  let(:db) do
    stub.quacks_like(Mongo::DB.allocate)
  end

  describe "#empty?" do

    context "when the slaves exist" do

      let(:slave) do
        Mongoid::Collections::Slaves.new([ db ], "people")
      end

      before do
        db.expects(:collection).with("people").returns(collection)
      end

      it "returns false" do
        slave.should_not be_empty
      end
    end

    context "when the slaves do not exist" do

      let(:slave) do
        Mongoid::Collections::Slaves.new([], "people")
      end

      it "returns true" do
        slave.should be_empty
      end
    end

    context "when the slaves are nil" do

      let(:slave) do
        Mongoid::Collections::Slaves.new(nil, "people")
      end

      it "returns true" do
        slave.should be_empty
      end
    end
  end

  context "Mongo::Collection operations" do

    let(:slave) do
      Mongoid::Collections::Slaves.new([ db ], "people")
    end

    before do
      db.expects(:collection).with("people").returns(collection)
    end

    Mongoid::Collections::Operations::READ.each do |name|

      it "defines #{name}" do
        slave.should respond_to(name)
      end

      describe "##{name}" do

        before do
          collection.expects(name)
        end

        it "delegates to the collection" do
          slave.send(name)
        end

        it "retries on connection failure" do
          slave.expects(:retry_on_connection_failure).then.yields
          slave.send(name)
        end
      end
    end
  end
end
