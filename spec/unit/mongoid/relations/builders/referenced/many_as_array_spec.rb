require "spec_helper"

describe Mongoid::Relations::Builders::Referenced::ManyAsArray do

  let(:klass) do
    Mongoid::Relations::Builders::Referenced::ManyAsArray
  end

  describe "#build" do

    let(:metadata) do
      stub(
        :klass => Post,
        :name => :posts,
        :foreign_key => "post_ids"
      )
    end

    let(:builder) do
      klass.new(metadata, object)
    end

    context "when provided an id array" do

      let(:object_id) do
        BSON::ObjectID.new
      end

      let(:object) do
        [ object_id ]
      end

      let(:post) do
        stub
      end

      before do
        Post.expects(:find).with([ object_id ]).returns([ post ])
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
