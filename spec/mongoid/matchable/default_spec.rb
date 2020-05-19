# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Matchable::Default do

  describe "#_matches?" do

    context "when comparing strings" do

      let(:matcher) do
        described_class.new("Testing")
      end

      context "when the values are equal" do

        it "returns true" do
          expect(matcher._matches?("Testing")).to be true
        end
      end

      context "when the values are not equal" do

        it "returns false" do
          expect(matcher._matches?("Other")).to be false
        end
      end
    end

    context "when comparing object ids" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:matcher) do
        described_class.new(object_id)
      end

      context "when the values are equal" do

        it "returns true" do
          expect(matcher._matches?(object_id)).to be true
        end
      end

      context "when the values are not equal" do

        it "returns false" do
          expect(matcher._matches?(BSON::ObjectId.new)).to be false
        end
      end
    end

    context "when comparing a string to an array" do

      let(:matcher) do
        described_class.new(["Test1", "Test2", "Test3"])
      end

      context "when the attribute contains the value" do

        context "when the value is a string" do

          it "returns true" do
            expect(matcher._matches?("Test1")).to be true
          end
        end

        context "when the value is a regexp" do

          it "returns true" do
            expect(matcher._matches?(/\ATest[3-5]\z/)).to be true
          end
        end
      end

      context "when the attribute does not contain the value" do

        it "returns false" do
          expect(matcher._matches?("Test4")).to be false
        end
      end
    end

    context "when comparing an object id to an array" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:matcher) do
        described_class.new([ object_id, BSON::ObjectId.new ])
      end

      context "when the attribute contains the value" do

        it "returns true" do
          expect(matcher._matches?(object_id)).to be true
        end
      end

      context "when the attribute does not contain the value" do

        it "returns false" do
          expect(matcher._matches?(BSON::ObjectId.new)).to be false
        end
      end
    end

    context "when comparing an array to an array" do

      let(:matcher) do
        described_class.new(["Test1", "Test2", "Test3"])
      end

      context "when the attribute equals the value" do

        it "returns true" do
          expect(matcher._matches?(["Test1", "Test2", "Test3"])).to be true
        end
      end

      context "when the value contains same items as attribute but in different order" do

        it "returns false" do
          expect(matcher._matches?(["Test1", "Test3", "Test2"])).to be false
        end
      end

      context "when the value is a subset of attribute" do

        it "returns false" do
          expect(matcher._matches?(["Test1", "Test2"])).to be false
        end
      end
    end
  end
end
