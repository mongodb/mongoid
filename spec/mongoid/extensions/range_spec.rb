# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Extensions::Range do

  describe "#__find_args__" do

    let(:range) do
      1..3
    end

    it "returns the range as an array" do
      expect(range.__find_args__).to eq([ 1, 2, 3 ])
    end
  end

  describe ".demongoize" do
    subject { Range.demongoize(hash) }

    context "when the range is ascending" do
      let(:hash) { { "min" => 1, "max" => 3 } }

      it "returns an ascending range" do
        is_expected.to eq(1..3)
      end
    end

    context "when the range is ascending with exclude end" do
      let(:hash) { { "min" => 1, "max" => 3, "exclude_end" => true } }

      it "returns an ascending range" do
        is_expected.to eq(1...3)
      end
    end

    context "when the range is descending" do
      let(:hash) { { "min" => 5, "max" => 1 } }

      it "returns an descending range" do
        is_expected.to eq(5..1)
      end
    end

    context "when the range is descending with exclude end" do
      let(:hash) { { "min" => 5, "max" => 1, "exclude_end" => true } }

      it "returns an descending range" do
        is_expected.to eq(5...1)
      end
    end

    context "when the range is letters" do
      let(:hash) { { "min" => "a", "max" => "z" } }

      it "returns an alphabetic range" do
        is_expected.to eq("a".."z")
      end
    end

    context "when the range is letters with exclude end" do
      let(:hash) { { "min" => "a", "max" => "z", "exclude_end" => true } }

      it "returns an alphabetic range" do
        is_expected.to eq("a"..."z")
      end
    end

    context "when the range is endless" do
      let(:hash) { { "min" => 1, "max" => nil } }

      context 'kernel can support endless range' do
        ruby_version_gte '2.6'

        it "returns an alphabetic range" do
          is_expected.to eq(1..)
        end
      end

      context 'kernel cannot support endless range' do
        ruby_version_lt '2.6'

        it "returns an alphabetic range" do
          is_expected.to eq(hash)
        end
      end
    end

    context "when the range is endless with exclude end" do
      let(:hash) { { "min" => 1, "max" => nil, "exclude_end" => true } }

      context 'kernel can support endless range' do
        ruby_version_gte '2.6'

        it "returns an alphabetic range" do
          is_expected.to eq(1...)
        end
      end

      context 'kernel cannot support endless range' do
        ruby_version_lt '2.6'

        it "returns an alphabetic range" do
          is_expected.to eq(hash)
        end
      end
    end

    context "when the range is beginning-less" do
      let(:hash) { { "min" => nil, "max" => 3 } }

      context 'kernel can support beginning-less range' do
        ruby_version_gte '2.7'

        it "returns an alphabetic range" do
          is_expected.to eq(nil..3)
        end
      end

      context 'kernel cannot support beginning-less range' do
        ruby_version_lt '2.7'

        it "returns an alphabetic range" do
          is_expected.to eq(hash)
        end
      end
    end

    context "when the range is beginning-less with exclude end" do
      let(:hash) { { "min" => nil, "max" => 3, "exclude_end" => true } }

      context 'kernel can support endless range' do
        ruby_version_gte '2.7'

        it "returns an alphabetic beginning-less" do
          is_expected.to eq(...3)
        end
      end

      context 'kernel cannot support beginning-less range' do
        ruby_version_lt '2.7'

        it "returns an alphabetic range" do
          is_expected.to eq(hash)
        end
      end
    end
  end

  shared_examples_for 'mongoize range' do

    context 'given a normal range' do
      let(:range) { 1..3 }

      it "returns the object hash" do
        is_expected.to eq("min" => 1, "max" => 3)
      end
    end

    context 'given a normal range not inclusive' do
      let(:range) { 1...3 }

      it "returns the object hash" do
        is_expected.to eq("min" => 1, "max" => 3, "exclude_end" => true)
      end
    end

    context 'given a descending range' do
      let(:range) { 5..1 }

      it "returns the object hash" do
        is_expected.to eq("min" => 5, "max" => 1)
      end
    end

    context 'given a descending range not inclusive' do
      let(:range) { 5...1 }

      it "returns the object hash" do
        is_expected.to eq("min" => 5, "max" => 1, "exclude_end" => true)
      end
    end

    context 'given an endless range' do
      ruby_version_gte '2.6'

      let(:range) { 5.. }

      it "returns the object hash" do
        is_expected.to eq("min" => 5)
      end
    end

    context 'given an endless range not inclusive' do
      ruby_version_gte '2.6'

      let(:range) { 5... }

      it "returns the object hash" do
        is_expected.to eq("min" => 5, "exclude_end" => true)
      end
    end

    context 'given a beginning-less range' do
      ruby_version_gte '2.7'

      let(:range) { ..5 }

      it "returns the object hash" do
        is_expected.to eq("max" => 5)
      end
    end

    context 'given an endless range not inclusive' do
      ruby_version_gte '2.7'

      let(:range) { ...5 }

      it "returns the object hash" do
        is_expected.to eq("max" => 5, "exclude_end" => true)
      end
    end

    context 'given a letter range' do
      let(:range) { 'a'..'z' }

      it "returns the object hash" do
        is_expected.to eq("min" => "a", "max" => "z")
      end
    end

    context 'given a letter range not inclusive' do
      let(:range) { 'a'...'z' }

      it "returns the object hash" do
        is_expected.to eq("min" => "a", "max" => "z", "exclude_end" => true)
      end
    end

    context 'given a Time range' do
      let(:range) { Time.at(0)..Time.at(1) }

      it "returns the object hash" do
        is_expected.to eq("min" => Time.at(0), "max" => Time.at(1))
        expect(subject["min"].utc?).to be(true)
        expect(subject["max"].utc?).to be(true)
      end
    end

    context 'given an ActiveSupport::TimeWithZone range' do
      let(:range) { Time.at(0)..Time.at(1) }

      it "returns the object hash" do
        is_expected.to eq("min" => Time.at(0).in_time_zone, "max" => Time.at(1).in_time_zone)
        expect(subject["min"].utc?).to be(true)
        expect(subject["max"].utc?).to be(true)
      end
    end

    context 'given a Date range' do
      let(:range) { Time.at(0).to_date..Time.at(1).to_date }

      it "returns the object hash" do
        is_expected.to eq("min" => Time.at(0).in_time_zone, "max" => Time.at(0).in_time_zone)
        expect(subject["min"].utc?).to be(true)
        expect(subject["max"].utc?).to be(true)
      end
    end

    context 'given a String' do
      let(:range) { '3' }

      it 'returns a string' do
        is_expected.to eq('3')
      end
    end

    context "given nil" do
      let(:range) { nil }

      it "returns nil" do
        is_expected.to be_nil
      end
    end
  end

  describe "#mongoize" do
    subject { range.mongoize }

    it_behaves_like 'mongoize range'
  end

  describe ".mongoize" do
    subject { Range.mongoize(range) }

    it_behaves_like 'mongoize range'
  end

  describe "#resizable?" do
    let(:range) do
      1...3
    end

    it "returns true" do
      expect(range).to be_resizable
    end
  end
end
