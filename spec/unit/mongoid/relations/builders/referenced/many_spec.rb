require "spec_helper"

describe Mongoid::Relations::Builders::Referenced::Many do

  describe "#build" do

    let(:criteria) do
      stub(:klass => Post, :selector => { "person_id" => "" })
    end

    let(:metadata) do
      stub_everything(
        :klass => Post,
        :name => :posts,
        :foreign_key => "person_id",
        :inverse_klass => Person,
        :criteria => criteria
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
        @documents = builder.build
      end

      it "sets the documents" do
        @documents.should eq(criteria)
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
          :criteria => criteria
        )
      end

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
        @documents = builder.build
      end

      it "ordered by specified filed" do
        @documents.should eq(criteria)
      end
    end

    context "when provided a object" do

      let(:metadata) do
        stub_everything(
          :klass => Post,
          :name => :posts,
          :foreign_key => "person_id",
          :inverse_klass => Person
        )
      end

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
