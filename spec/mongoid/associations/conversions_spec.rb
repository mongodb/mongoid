require "spec_helper"

describe Mongoid::Associations::Conversions do

  describe ".flag" do

    context "when the inverse uses object ids" do

      let(:association) do
        Person.relations["game"]
      end

      let(:object) do
        BSON::ObjectId.new
      end

      let(:flagged) do
        association.flag(object)
      end

      it "returns the object" do
        expect(flagged).to eq(object)
      end
    end

    context "when the inverse uses string ids" do

      before do
        Person.field(
          :_id,
          type: String,
          pre_processed: true,
          overwrite: true,
          default: ->{ BSON::ObjectId.new.to_s }
        )
      end

      after do
        Person.field(
          :_id,
          type: BSON::ObjectId,
          pre_processed: true,
          overwrite: true,
          default: ->{ BSON::ObjectId.new }
        )
      end

      let(:association) do
        Person.relations["game"]
      end

      context "when provided an object id" do

        let(:object) do
          BSON::ObjectId.new
        end

        let(:flagged) do
          association.flag(object)
        end

        it "returns the object id" do
          expect(flagged).to eq(object)
        end
      end

      context "when provided a string" do

        let(:object) do
          BSON::ObjectId.new.to_s
        end

        let(:flagged) do
          association.flag(object)
        end

        it "returns the string" do
          expect(flagged).to eq(object)
        end

        it "marks the string as unconvertable" do
          expect(flagged).to be_unconvertable_to_bson
        end
      end
    end

    context "when the inverse uses integer ids" do

      let(:association) do
        Jar.relations["cookies"]
      end

      context "when provided an object id" do

        let(:object) do
          BSON::ObjectId.new
        end

        let(:flagged) do
          association.flag(object)
        end

        it "returns the object id" do
          expect(flagged).to eq(object)
        end
      end

      context "when provided an integer" do

        let(:object) do
          15
        end

        let(:flagged) do
          association.flag(object)
        end

        it "returns the integer" do
          expect(flagged).to eq(15)
        end

        it "marks the integer as unconvertable" do
          expect(flagged).to be_unconvertable_to_bson
        end
      end
    end
  end
end
