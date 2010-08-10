require "spec_helper"

describe Mongoid::Relations::Builders::Referenced::In do

  let(:klass) do
    Mongoid::Relations::Builders::Referenced::In
  end

  describe "#build" do

    let(:metadata) do
      stub(
        :klass => Person,
        :name => :person,
        :foreign_key => "person_id"
      )
    end

    let(:builder) do
      klass.new(metadata, object)
    end

    context "when provided an id" do

      let(:object_id) do
        BSON::ObjectID.new
      end

      let(:object) do
        { "person_id" => object_id }
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
        stub(:attributes => {})
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
