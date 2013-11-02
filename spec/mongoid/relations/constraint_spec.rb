require "spec_helper"

describe Mongoid::Relations::Constraint do

  describe "#convert" do

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

      let(:metadata) do
        Mongoid::Relations::Metadata.new(
          class_name: "Person",
          name: :person,
          inverse_class_name: "Post",
          relation: Mongoid::Relations::Referenced::In
        )
      end

      let(:constraint) do
        described_class.new(metadata)
      end

      context "when provided an object id" do

        let(:object) do
          BSON::ObjectId.new
        end

        it "returns the object id" do
          expect(constraint.convert(object)).to eq(object)
        end
      end

      context "when provided a string" do

        let(:object) do
          BSON::ObjectId.new
        end

        it "returns an object id from the string" do
          expect(constraint.convert(object.to_s)).to eq(object)
        end
      end
    end

    context "when the id's class does not store object ids" do

      let(:metadata) do
        Mongoid::Relations::Metadata.new(
          class_name: "Account",
          name: :account,
          inverse_class_name: "Alert",
          relation: Mongoid::Relations::Referenced::In
        )
      end

      let(:constraint) do
        described_class.new(metadata)
      end

      it "returns the object" do
        expect(constraint.convert("testing")).to eq("testing")
      end
    end
  end
end
