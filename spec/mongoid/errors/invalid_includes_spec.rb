require "spec_helper"

describe Mongoid::Errors::InvalidIncludes do

  describe "#message" do

    context "default" do

      let(:klass) do
        Band
      end

      let(:args) do
        [ :members ]
      end

      let(:error) do
        described_class.new(klass, args)
      end

      it "contains the problem in the message" do
        expect(error.message).to include(
          "Invalid includes directive: Band.includes(:members)"
        )
      end

      it "contains the summary in the message" do
        expect(error.message).to include(
          "Eager loading in Mongoid only supports providing arguments to Band.includes"
        )
      end

      it "contains the resolution in the message" do
        expect(error.message).to include(
          "Ensure that each parameter passed to Band.includes is a valid name"
        )
      end
    end
  end
end
