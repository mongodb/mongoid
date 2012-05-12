require "spec_helper"

describe Mongoid::Fields::Standard do

  describe "#pre_processed?" do

    context "when the field has a default" do

      context "when the default is a proc" do

        context "when the pre-processed option is true" do

          let(:field) do
            described_class.new(
              :test,
              default: ->{ "testing" },
              pre_processed: true,
              type: String
            )
          end

          it "returns true" do
            field.should be_pre_processed
          end
        end

        context "when the pre-processed option is not true" do

          let(:field) do
            described_class.new(
              :test,
              default: ->{ "testing" },
              type: String
            )
          end

          it "returns false" do
            field.should_not be_pre_processed
          end
        end
      end

      context "when the default is not a proc" do

        let(:field) do
          described_class.new(
            :test,
            default: "testing",
            type: String
          )
        end

        it "returns true" do
          field.should be_pre_processed
        end
      end
    end

    context "when the field has no default" do

      let(:field) do
        described_class.new(
          :test,
          type: String
        )
      end

      it "returns false" do
        field.should_not be_pre_processed
      end
    end
  end

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

  context "when using a custom serializable field" do

    let(:model) do
      Class.new(Person) do
        field(:image, :type => Image)
      end
    end

    let(:doc) do
      model.new(:image => "avatar.jpg")
    end

    let(:field) do
      doc.fields["image"]
    end

    let(:image) do
      doc.image
    end

    let(:image_id) do
      doc.image.object_id
    end

    it "returns the correct value" do
      doc.image.name.should eq("avatar.jpg")
    end

    it "retains the same instance of the value" do
      object_id = doc.image.object_id
      3.times{ doc.image.object_id.should eq(object_id) }
    end

    context "when writing a new value" do

      before do
        doc.write_attribute(:image, "new_avatar.jpg")
      end

      it "returns the correct value" do
        doc.image.name.should eq("new_avatar.jpg")
      end

      it "retains the same instance of the new value" do
        object_id = doc.image.object_id
        3.times{ doc.image.object_id.should eq(object_id) }
      end
    end

    context "when accessing the field multiple times" do

      context "when first accessing the map" do

        it "has no demongoized values" do
          doc.demongoized.should be_empty
        end
      end

      let(:attribute) do
        doc.read_attribute(:image)
      end

      let(:image) do
        doc.image
      end

      let(:identity) do
        [ attribute.object_id, attribute.hash ]
      end

      it "uses the proper identity" do
        field.demongoized_identity_for(attribute).should eq(identity)
      end

      it "sets the object in the demongoized map" do
        doc.demongoized.should eq({ "image" => { identity => image }})
      end

      it "contains only one reference to previously demongoized objects" do
        3.times do
          name = doc.image.name.succ
          doc.write_attribute(:image, name)

          object_id = doc.image.object_id
          3.times{ doc.image.object_id.should eq(object_id) }

          attribute = doc.read_attribute("image")
          image     = doc.image
          identity  = [attribute.object_id, attribute.hash]

          field.demongoized_identity_for(attribute).should eq(identity)
          doc.demongoized.should eq({ "image" => { identity => image }})
        end
      end
    end
  end

  context "when subclassing a serializable field" do

    let(:thumbnail) do
      Thumbnail.new("test")
    end

    it "inherits the parents deserialize method" do
      Thumbnail.demongoize("testy").name.should eq("testy")
    end

    it "inherits the parents serialize method" do
      thumbnail.mongoize.should eq("test")
    end

    context "when instantiating the class" do

      let(:movie) do
        Movie.new(
          poster: Image.new("poster"),
          poster_thumb: Thumbnail.new("thumb")
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
