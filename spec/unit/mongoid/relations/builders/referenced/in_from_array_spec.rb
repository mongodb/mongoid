require "spec_helper"

describe Mongoid::Relations::Builders::Referenced::InFromArray do

  let(:klass) do
    Mongoid::Relations::Builders::Referenced::InFromArray
  end

  describe "#build" do

    let(:metadata) do
      stub(
        :klass => Person,
        :name => :person,
        :foreign_key => "post_ids"
      )
    end

    let(:builder) do
      klass.new(metadata, object)
    end

    context "when provided a hash" do

      let(:object_id) do
        BSON::ObjectID.new
      end

      let(:object) do
        { "_id" => object_id }
      end

      let(:person) do
        stub
      end

      before do
        Person.expects(:any_in).with(
          "post_ids" => [ object_id ]
        ).returns([ person ])
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
