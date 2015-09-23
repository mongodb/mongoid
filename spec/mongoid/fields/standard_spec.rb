require "spec_helper"

describe Mongoid::Fields::Standard do

  describe "#lazy?" do

    let(:field) do
      described_class.new(:test, type: String)
    end

    it "returns false" do
      expect(field).to_not be_lazy
    end
  end

  describe "#pre_processed?" do

    before(:all) do
      class FieldTest
        include Mongoid::Document
      end
    end

    after(:all) do
      Object.send(:remove_const, :FieldTest)
    end

    context "when the field has a default" do

      context "when the default is a proc" do

        context "when the pre-processed option is true" do

          let(:field) do
            described_class.new(
              :test,
              default: ->{ "testing" },
              pre_processed: true,
              klass: FieldTest,
              type: String
            )
          end

          it "returns true" do
            expect(field).to be_pre_processed
          end
        end

        context "when the pre-processed option is not true" do

          let(:field) do
            described_class.new(
              :test,
              default: ->{ "testing" },
              klass: FieldTest,
              type: String
            )
          end

          it "returns false" do
            expect(field).to_not be_pre_processed
          end
        end
      end

      context "when the default is not a proc" do

        let(:field) do
          described_class.new(
            :test,
            default: "testing",
            klass: FieldTest,
            type: String
          )
        end

        it "returns true" do
          expect(field).to be_pre_processed
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
        expect(field).to_not be_pre_processed
      end
    end
  end

  context "when checking hash values in a custom serializer" do

    let(:image) do
      Image.new("test")
    end

    it "does not conflict with the ruby core hash" do
      expect(image.hash_is_hash).to be true
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
        expect(hash[:key]).to eq("value")
      end
    end

    context "when getting a non existent value" do

      it "returns nil" do
        expect(hash[:key]).to be_nil
      end
    end
  end

  context "when subclassing a serializable field" do

    let(:thumbnail) do
      Thumbnail.new("test")
    end

    it "inherits the parents deserialize method" do
      expect(Thumbnail.demongoize("testy").name).to eq("testy")
    end

    it "inherits the parents serialize method" do
      expect(thumbnail.mongoize).to eq("test")
    end

    context "when instantiating the class" do

      let(:movie) do
        Movie.new(
          poster: Image.new("poster"),
          poster_thumb: Thumbnail.new("thumb")
        )
      end

      it "deserializes the parent type" do
        expect(movie.poster.name).to eq("poster")
      end

      it "deserializes the child type" do
        expect(movie.poster_thumb.name).to eq("thumb")
      end
    end
  end
end
