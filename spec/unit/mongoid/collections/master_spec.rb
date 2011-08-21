require "spec_helper"

describe Mongoid::Collections::Master do

  let(:collection) do
    stub.quacks_like(Mongo::Collection.allocate)
  end

  let(:db) do
    stub.quacks_like(Mongo::DB.allocate)
  end

  let(:master) do
    Mongoid::Collections::Master.new(db, "people")
  end

  before do
    db.expects(:create_collection).with("people", {}).returns(collection)
  end

  context "Mongo::Collection operations" do

    Mongoid::Collections::Operations::ALL.each do |name|

      it "defines #{name}" do
        master.should respond_to(name)
      end

      describe "##{name}" do

        before do
          collection.expects(name)
        end

        it "delegates to the collection" do
          master.send(name)
        end

        it "retries on connection failure" do
          master.expects(:retry_on_connection_failure).then.yields
          master.send(name)
        end
      end
    end
  end
end
