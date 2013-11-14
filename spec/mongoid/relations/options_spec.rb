require "spec_helper"

describe Mongoid::Relations::Options do

  describe ".validate!" do

    let(:relation) do
      Mongoid::Relations::Embedded::Many
    end

    context "when the options are valid for the relation" do

      let(:options) do
        { relation: relation, as: :addressable }
      end

      it "returns true" do
        expect(described_class.validate!(options)).to be true
      end
    end

    context "when the options are invalid for the relation" do

      let(:options) do
        { name: :addresses, relation: relation, polymorphic: true }
      end

      it "raises an error" do
        expect {
          described_class.validate!(options)
        }.to raise_error(Mongoid::Errors::InvalidOptions)
      end
    end
  end
end
