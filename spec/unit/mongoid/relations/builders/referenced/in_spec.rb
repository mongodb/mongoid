require "spec_helper"

describe Mongoid::Relations::Builders::Referenced::In do

  describe "#build" do

    let(:metadata) do
      stub(
        :klass => Person,
        :name => :person,
        :foreign_key => "person_id"
      )
    end

    let(:builder) do
      described_class.new(metadata, object)
    end

    context "when provided an id" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:object) do
        object_id
      end

      let(:person) do
        stub
      end

      before do
        Person.expects(:find).with(object_id).returns(person)
        @document = builder.build
      end

      it "sets the document" do
        @document.should == person
      end
    end

    context "when provided a object" do

      let(:object) do
        Person.new
      end

      before do
        @document = builder.build
      end

      it "returns the object" do
        @document.should == object
      end
    end
  end
end
