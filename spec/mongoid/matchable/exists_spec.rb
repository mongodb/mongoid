# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Matchable::Exists do

  describe "#_matches?" do

    context "when checking for existence" do

      context "when the value exists" do

        let(:matcher) do
          described_class.new("Test")
        end

        it "returns true" do
          expect(matcher._matches?("$exists" => true)).to be true
        end
      end

      context "when the value does not exist" do

        let(:matcher) do
          described_class.new(nil)
        end

        it "returns false" do
          expect(matcher._matches?("$exists" => true)).to be false
        end
      end
    end

    context "when checking for nonexistence" do

      context "when the value exists" do

        let(:matcher) do
          described_class.new("Test")
        end

        it "returns false" do
          expect(matcher._matches?("$exists" => false)).to be false
        end
      end

      context "when the value does not exist" do

        let(:matcher) do
          described_class.new(nil)
        end

        it "returns true" do
          expect(matcher._matches?("$exists" => false)).to be true
        end
      end
    end
  end
end
