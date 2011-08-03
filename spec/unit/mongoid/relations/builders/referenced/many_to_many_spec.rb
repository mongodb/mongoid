require "spec_helper"

describe Mongoid::Relations::Builders::Referenced::ManyToMany do

  describe "#build" do

    let(:metadata) do
      stub_everything(
        :klass => Post,
        :name => :posts,
        :foreign_key => "post_ids",
        :criteria => [ post ]
      )
    end

    let(:builder) do
      described_class.new(metadata, object)
    end

    context "when provided ids" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:object) do
        [ object_id ]
      end

      let(:post) do
        stub
      end

      let(:documents) do
        builder.build
      end

      it "sets the documents" do
        documents.should == [ post ]
      end
    end

    context "when order specified" do

      let(:metadata) do
        stub_everything(
          :klass => Post,
          :name => :posts,
          :foreign_key => "person_id",
          :inverse_klass => Person,
          :order => :rating.asc,
          :criteria => [ post ]
        )
      end

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:object) do
        [ object_id ]
      end

      let(:post) do
        stub
      end

      before do
        @documents = builder.build
      end

      it "ordered by specified filed" do
        @documents.should == [ post ]
      end
    end

    context "when provided a object" do

      context "when the object is not nil" do

        let(:object) do
          [ Post.new ]
        end

        let(:post) do
          stub
        end

        let!(:documents) do
          builder.build
        end

        it "returns the objects" do
          documents.should == object
        end
      end

      context "when the object is nil" do

        let(:metadata) do
          stub_everything(
            :klass => Post,
            :name => :posts,
            :foreign_key => "post_ids",
            :criteria => nil
          )
        end

        let(:object) do
          nil
        end

        let!(:documents) do
          builder.build
        end

        it "returns the object" do
          documents.should be_nil
        end
      end
    end
  end
end
