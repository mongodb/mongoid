require "spec_helper"

describe Mongoid::Contexts::Enumerable::Sort do

  describe "#initialize" do

    let(:sort) do
      described_class.new("value", 1)
    end

    it "sets the value" do
      sort.value.should eq("value")
    end

    it "sets the sort order" do
      sort.direction.should eq(1)
    end
  end

  describe "#ascending?" do

    context "when the direction is 1" do

      let(:sort) do
        described_class.new("", 1)
      end

      it "returns true" do
        sort.should be_ascending
      end
    end

    context "when the direction is -1" do

      let(:sort) do
        described_class.new("", -1)
      end

      it "returns false" do
        sort.should_not be_ascending
      end
    end
  end

  describe "#compare" do

    subject do
      described_class.allocate.send(:compare, value, other_value)
    end

    context "when a is nil" do

      let(:value) do
        nil
      end

      context "and b is nil" do

        let(:other_value) do
          nil
        end

        it { should eq(0) }
      end

      context "and b is not nil" do

        let(:other_value) do
          "a"
        end

        it { should eq(1) }
      end
    end

    context "when a is not nil" do

      let(:value) do
        "a"
      end

      context "and b is nil" do

        let(:other_value) do
          nil
        end

        it { should eq(-1) }
      end

      context "and b is not nil" do

        let(:other_value) do
          "b"
        end

        it "uses default comparison" do
          value.expects(:<=>).with(other_value)
          subject
        end
      end
    end
  end

  describe "<=>" do

    context "when direction is ascending" do

      let(:sort) do
        described_class.new(0, 1)
      end

      let(:other) do
        stub(value: 1)
      end

      it "returns the results of compare" do
        sort.expects(:compare).with(0, other.value).returns(-1)
        (sort <=> other).should eq(-1)
      end
    end

    context "when direction is descending" do

      let(:sort) do
        described_class.new(0, -1)
      end

      let(:other) do
        stub(value: 1)
      end

      it "returns the inverse of compare" do
        sort.expects(:compare).with(0, other.value).returns(-1)
        (sort <=> other).should eq(1)
      end
    end
  end
end
