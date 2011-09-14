require "spec_helper"

describe Mongoid::Collection do

  describe "#initialize" do

    context "when providing options" do

      let(:capped) do
        described_class.new(
          Person,
          "capped_people",
          :capped => true, :size => 10000, :max => 100
        )
      end

      let(:options) do
        capped.options
      end

      it "sets the capped option" do
        options["capped"].should be_true
      end

      it "sets the capped size" do
        options["size"].should eq(10000)
      end

      it "sets the max capped documents" do
        options["max"].should eq(100)
      end
    end
  end
end
