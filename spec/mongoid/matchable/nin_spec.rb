# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Matchable::Nin do

  describe "#_matches?" do

    context 'when the attribute is not nil' do

    let(:matcher) do
      described_class.new("first")
    end

      context "when the values do not contain the attribute" do

        it "returns true" do
          expect(matcher._matches?("$nin" => ["second", "third"])).to be true
        end
      end

      context "when the values contain the attribute" do

        it "returns false" do
          expect(matcher._matches?("$nin" => ["first"])).to be false
        end
      end
    end

    context 'when the attribute is nil' do
      let(:matcher) do
        described_class.new(nil)
      end

      context "when the values do not contain the attribute" do

        it "returns true" do
          expect(matcher._matches?("$nin" => ["third"])).to be true
        end
      end

      context "when the values contain the attribute" do

        it "returns false" do
          expect(matcher._matches?("$nin" => [/\Afir.*\z/, nil])).to be false
        end
      end
    end
  end
end
