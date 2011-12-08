require "spec_helper"

describe Mongoid::Fields::Serializable do

  context "when checking hash values in a custom serializer" do

    let(:image) do
      Image.new("test")
    end

    it "does not conflict with the ruby core hash" do
      image.hash_is_hash.should be_true
    end
  end

  context "when included in a hash" do

    let(:hash) do
      MyHash.new
    end

    context "when setting a value" do

      before do
        hash[:key] = "value"
      end

      it "allows normal hash access" do
        hash[:key].should eq("value")
      end
    end

    context "when getting a non existant value" do

      it "returns nil" do
        hash[:key].should be_nil
      end
    end
  end

  context "when subclassing a serializable field" do

    let(:thumbnail) do
      Thumbnail.new("test")
    end

    it "inherits the parents deserialize method" do
      thumbnail.deserialize("testy").name.should eq("testy")
    end

    it "inherits the parents serialize method" do
      thumbnail.serialize(thumbnail).should eq("test")
    end

    context "when instantiating the class" do

      let(:movie) do
        Movie.new(
          :poster => Image.new("poster"),
          :poster_thumb => Thumbnail.new("thumb")
        )
      end

      it "deserializes the parent type" do
        movie.poster.name.should eq("poster")
      end

      it "deserializes the child type" do
        movie.poster_thumb.name.should eq("thumb")
      end
    end
  end
end
