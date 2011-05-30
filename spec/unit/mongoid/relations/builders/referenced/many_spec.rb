require "spec_helper"

describe Mongoid::Relations::Builders::Referenced::Many do

  describe "#build" do

    let(:metadata) do
      stub(
        :klass => Post,
        :name => :posts,
        :foreign_key => "person_id",
        :inverse_klass => Person
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

      let(:post) do
        stub
      end

      before do
        Post.expects(:where).with("person_id" => object_id).returns([ post ])
        @documents = builder.build
      end

      it "sets the documents" do
        @documents.should == [ post ]
      end
    end

    context "when provided a object" do

      let(:object) do
        [ Person.new ]
      end

      before do
        @documents = builder.build
      end

      it "returns the object" do
        @documents.should == object
      end
    end
  end
end
