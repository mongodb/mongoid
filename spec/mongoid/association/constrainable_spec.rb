require "spec_helper"

describe Mongoid::Association::Constrainable do

  describe "#convert_to_foreign_key" do

    context "when the id's class stores object ids" do

      before(:all) do
        Person.field(
          :_id,
          type: BSON::ObjectId,
          pre_processed: true,
          default: ->{ BSON::ObjectId.new },
          overwrite: true
        )
      end

      let(:constrainable) do
        Post.belongs_to :person
      end

      context "when provided an object id" do

        let(:object) do
          BSON::ObjectId.new
        end

        it "returns the object id" do
          expect(constrainable.convert_to_foreign_key(object)).to eq(object)
        end
      end

      context "when provided a string" do

        let(:object) do
          BSON::ObjectId.new
        end

        it "returns an object id from the string" do
          expect(constrainable.convert_to_foreign_key(object.to_s)).to eq(object)
        end
      end
    end

    context "when the id's class does not store object ids" do

      let(:constrainable) do
        Alert.belongs_to :account
      end

      it "returns the object" do
        expect(constrainable.convert_to_foreign_key("testing")).to eq("testing")
      end
    end
  end
end
