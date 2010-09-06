require "spec_helper"

describe Mongoid::Relations::Builders::Referenced::One do

  let(:klass) do
    Mongoid::Relations::Builders::Referenced::One
  end

  describe "#build" do

    let(:metadata) do
      stub(
        :klass => Post,
        :name => :post,
        :foreign_key => "person_id"
      )
    end

    let(:builder) do
      klass.new(metadata, object)
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
        Post.expects(:first).with(
          :conditions => { "person_id" => object }
        ).returns(post)
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
