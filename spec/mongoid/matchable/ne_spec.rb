# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Matchable::Ne do

  let(:matcher) do
    described_class.new("first")
  end

  describe "#_matches?" do

    context "when the values are not equal" do

      it "returns true" do
        expect(matcher._matches?("$ne" => "second")).to be true
      end
    end

    context "when the values are equal" do

      it "returns false" do
        expect(matcher._matches?("$ne" => "first")).to be false
      end
    end

    context "when the value is an array" do

      let(:array_matcher) do
        described_class.new([ "first" ])
      end

      context "when the value is in the array" do

        it "returns false" do
          expect(array_matcher._matches?("$ne" => "first")).to be false
        end
      end

      context "when the value is not in the array" do

        it "returns true" do
          expect(array_matcher._matches?("$ne" => "second")).to be true
        end
      end
    end
  end
end
