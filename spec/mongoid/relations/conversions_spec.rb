require "spec_helper"

describe Mongoid::Relations::Conversions do

  describe ".flag" do

    context "when the inverse uses object ids" do

      let(:metadata) do
        Person.relations["game"]
      end

      let(:object) do
        Moped::BSON::ObjectId.new
      end

      let(:flagged) do
        described_class.flag(object, metadata)
      end

      it "returns the object" do
        flagged.should eq(object)
      end
    end

    context "when the inverse uses string ids" do

      before do
        Person.field(
          :_id,
          type: String,
          pre_processed: true,
          default: ->{ Moped::BSON::ObjectId.new.to_s }
        )
      end

      after do
        Person.field(
          :_id,
          type: Moped::BSON::ObjectId,
          pre_processed: true,
          default: ->{ Moped::BSON::ObjectId.new }
        )
      end

      let(:metadata) do
        Person.relations["game"]
      end

      context "when provided an object id" do

        let(:object) do
          Moped::BSON::ObjectId.new
        end

        let(:flagged) do
          described_class.flag(object, metadata)
        end

        it "returns the object id" do
          flagged.should eq(object)
        end
      end

      context "when provided a string" do

        let(:object) do
          Moped::BSON::ObjectId.new.to_s
        end

        let(:flagged) do
          described_class.flag(object, metadata)
        end

        it "returns the string" do
          flagged.should eq(object)
        end

        it "marks the string as unconvertable" do
          flagged.should be_unconvertable_to_bson
        end
      end
    end

    context "when the inverse uses integer ids" do

      let(:metadata) do
        Jar.relations["cookies"]
      end

      context "when provided an object id" do

        let(:object) do
          Moped::BSON::ObjectId.new
        end

        let(:flagged) do
          described_class.flag(object, metadata)
        end

        it "returns the object id" do
          flagged.should eq(object)
        end
      end

      context "when provided an integer" do

        let(:object) do
          15
        end

        let(:flagged) do
          described_class.flag(object, metadata)
        end

        it "returns the integer" do
          flagged.should eq(15)
        end

        it "marks the integer as unconvertable" do
          flagged.should be_unconvertable_to_bson
        end
      end
    end
  end
end
