require "spec_helper"

describe Mongoid::Relations::Builders::Referenced::One do

  describe "#build" do

    let(:metadata) do
      stub(
        :klass => Post,
        :name => :post,
        :foreign_key => "person_id"
      )
    end

    let(:builder) do
      described_class.new(metadata, object)
    end

    let(:criteria) do
      stub
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
        Post.expects(:where).with("person_id" => object).returns(criteria)
        criteria.expects(:first).returns(post)
        @documents = builder.build
      end

      it "sets the document" do
        @documents.should == post
      end
    end

    context "when provided a object" do

      let(:object) do
        Post.new
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
