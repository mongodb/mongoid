require "spec_helper"

describe Mongoid::Extensions::Regexp do

  describe ".demongoize" do

    let(:value) do
      Regexp.demongoize(/[^abc]/)
    end

    it "returns the provided value" do
      value.should eq(/[^abc]/)
    end
  end

  describe ".mongoize" do

    context "when providing a regex" do

      let(:value) do
        Regexp.mongoize(/[^abc]/)
      end

      it "returns the provided value" do
        value.should eq(/[^abc]/)
      end
    end

    context "when providing a string" do

      let(:value) do
        Regexp.mongoize("[^abc]")
      end

      it "returns the provided value as a regex" do
        value.should eq(/[^abc]/)
      end
    end
  end

  describe "#mongoize" do

    it "returns self" do
      /[^abc]/.mongoize.should eq(/[^abc]/)
    end
  end
end
