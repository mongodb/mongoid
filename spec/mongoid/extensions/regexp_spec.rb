# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Extensions::Regexp do

  describe ".demongoize" do

    let(:value) do
      Regexp.demongoize(/[^abc]/)
    end

    it "returns the provided value" do
      expect(value).to eq(/[^abc]/)
    end
  end

  describe ".mongoize" do

    context "when providing a regex" do

      let(:value) do
        Regexp.mongoize(/[^abc]/)
      end

      it "returns the provided value" do
        expect(value).to eq(/[^abc]/)
      end
    end

    context "when providing a string" do

      let(:value) do
        Regexp.mongoize("[^abc]")
      end

      it "returns the provided value as a regex" do
        expect(value).to eq(/[^abc]/)
      end


      context "when the string is empty" do

        let(:value) do
          Regexp.mongoize("")
        end

        it "returns an empty regex" do
          expect(value).to eq(//)
        end
      end
    end

    context "when the value is nil" do

      let(:value) do
        Regexp.mongoize(nil)
      end

      it "returns the nil" do
        expect(value).to be_nil
      end
    end
  end

  describe "#mongoize" do

    it "returns self" do
      expect(/[^abc]/.mongoize).to eq(/[^abc]/)
    end
  end
end
