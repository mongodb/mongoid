# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Matchable::ElemMatch do

  let(:attribute) {[{"a" => 1, "b" => 2}, {"a" => 2, "b" => 2}, {"a" => 3, "b" => 1}]}
  let(:matcher) do
    described_class.new(attribute)
  end

  describe "#_matches?" do

    context "when the attribute is not an array" do

      let(:attribute) {"string"}

      it "returns false" do
        expect(matcher._matches?("$elemMatch" => {"a" => 1})).to be false
      end
    end

    context "when the $elemMatch is not a hash" do

      let(:attribute) {"string"}

      it "returns false" do
        expect(matcher._matches?("$elemMatch" => [])).to be false
      end
    end

    context "when there is a sub document that matches the criteria" do

      it "returns true" do
        expect(matcher._matches?("$elemMatch" => {"a" => 1})).to be true
      end

      context "when evaluating multiple fields of the subdocument" do

        it "returns true" do
          expect(matcher._matches?("$elemMatch" => {"a" => 1, "b" => 2})).to be true
        end

        context "when the $elemMatch document keys are out of order" do

          it "returns true" do
            expect(matcher._matches?("$elemMatch" => {"b" => 2, "a" => 1})).to be true
          end
        end
      end

      context "when using other operators that match" do

        it "returns true" do
          expect(matcher._matches?("$elemMatch" => {"a" => {"$in" => [1]}, "b" => {"$gt" => 1}})).to be true
        end
      end

      context "when using a $not operator that matches" do

        it "returns true" do
          expect(matcher._matches?("$elemMatch" => {"a" => {"$not" => 4}})).to be true
        end
      end
    end

    context "when using symbols and a :$not operator that matches" do
      it "returns true" do
        expect(matcher._matches?(:$elemMatch => {"a" => {:$not => 4}})).to be true
      end
    end

    context "when there is not a sub document that matches the criteria" do

      it "returns false" do
        expect(matcher._matches?("$elemMatch" => {"a" => 10})).to be false
      end

      context "when evaluating multiple fields of the subdocument" do

        it "returns false" do
          expect(matcher._matches?("$elemMatch" => {"a" => 1, "b" => 3})).to be false
        end
      end

      context "when using other operators that do not match" do

        it "returns true" do
          expect(matcher._matches?("$elemMatch" => {"a" => {"$in" => [1]}, "b" => {"$gt" => 10}})).to be false
        end
      end

      context "when using a $not operator that does not match" do

        it "returns true" do
          expect(matcher._matches?("$elemMatch" => {"a" => {"$not" => 1}})).to be true
        end
      end
    end

    context "when using a criteria that matches partially but not a single sub document" do

      it "returns false" do
        expect(matcher._matches?("$elemMatch" => {"a" => 3, "b" => 2})).to be false
      end
    end
  end
end
