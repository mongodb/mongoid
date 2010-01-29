require "spec_helper"

describe Mongoid::Criterion::Union do

  let(:collection) do
    stub.quacks_like(Mongoid::Criterion::TempCollection.allocate)
  end

  describe "#or" do

    before do
      @first = Mongoid::Criteria.new(Person)
      @second = Mongoid::Criteria.new(Person)
    end

    context "when combining criteria" do

      context "when a capped collection exists" do

        before do
          @first.instance_variable_set(:@temp_collection, collection)
        end

        it "gets the collection" do
          @first.or(@second)
          @first.temp_collection.should == collection
        end

      end

      context "when a capped collection does not exist" do

        before do
          Mongoid::Criterion::TempCollection.expects(:new).returns(collection)
        end

        it "creates a new capped collection" do
          @first.or(@second)
          @first.temp_collection.should == collection
        end

      end

    end

  end

end
