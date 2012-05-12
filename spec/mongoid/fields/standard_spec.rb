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

    it "returns values based on attribute identity" do
      doc.image.name.should eq("avatar.jpg")

      object_id = doc.image.object_id
      3.times{ doc.image.object_id.should eq(object_id) }

      doc.write_attribute(:image, "new_avatar.jpg")

      doc.image.name.should eq("new_avatar.jpg")

      object_id = doc.image.object_id
      3.times{ doc.image.object_id.should eq(object_id) }
    end

    it "hold just *one* reference to previously demongoized objects to prevent leaks" do
      doc.demongoized.should be_empty

      object_id = doc.image.object_id
      3.times{ doc.image.object_id.should eq(object_id) }

      attribute = doc.read_attribute("image")
      image     = doc.image
      identity  = [attribute.object_id, attribute.hash]

      field.demongoized_identity_for(attribute).should eq(identity)
      doc.demongoized.should eq({"image" => {identity => image}})

      3.times do
        name = doc.image.name.succ
        doc.write_attribute(:image, name)

        object_id = doc.image.object_id

        object_id = doc.image.object_id
        3.times{ doc.image.object_id.should eq(object_id) }

        attribute = doc.read_attribute("image")
        image     = doc.image
        identity  = [attribute.object_id, attribute.hash]

        field.demongoized_identity_for(attribute).should eq(identity)
        doc.demongoized.should eq({"image" => {identity => image}})
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
