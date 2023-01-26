# frozen_string_literal: true

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
          is_expected.to eq(eval('1..'))
        end
      end

      context 'kernel cannot support endless range' do
        ruby_version_lt '2.6'

        it "returns nil" do
          is_expected.to be nil
        end
      end
    end

    context "when the range is endless with exclude end" do
      let(:hash) { { "min" => 1, "max" => nil, "exclude_end" => true } }

      context 'kernel can support endless range' do
        ruby_version_gte '2.6'

        it "returns an alphabetic range" do
          is_expected.to eq(eval('1...'))
        end
      end

      context 'kernel cannot support endless range' do
        ruby_version_lt '2.6'

        it "returns nil" do
          is_expected.to be nil
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

        it "returns nil" do
          is_expected.to be nil
        end
      end
    end

    context "when the range is beginning-less with exclude end" do
      let(:hash) { { "min" => nil, "max" => 3, "exclude_end" => true } }

      context 'kernel can support endless range' do
        ruby_version_gte '2.7'

        it "returns an alphabetic beginning-less" do
          is_expected.to eq(eval('...3'))
        end
      end

      context 'kernel cannot support beginning-less range' do
        ruby_version_lt '2.7'

        it "returns nil" do
          is_expected.to be nil
        end
      end
    end

    context "when the range doesn't have any correct keys" do
      let(:hash) { { "min^" => "a", "max^" => "z", "exclude_end^" => true } }

      it "returns nil" do
        is_expected.to be nil
      end
    end

    context "when the range has symbol keys" do
      let(:hash) { { min: 1, max: 3 } }

      it "returns an ascending range" do
        is_expected.to eq(1..3)
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

      let(:range) { eval('5..') }

      it "returns the object hash" do
        is_expected.to eq("min" => 5)
      end
    end

    context 'given an endless range not inclusive' do
      ruby_version_gte '2.6'

      let(:range) { eval('5...') }

      it "returns the object hash" do
        is_expected.to eq("min" => 5, "exclude_end" => true)
      end
    end

    context 'given a beginning-less range' do
      ruby_version_gte '2.7'

      let(:range) { eval('..5') }

      it "returns the object hash" do
        is_expected.to eq("max" => 5)
      end
    end

    context 'given an endless range not inclusive' do
      ruby_version_gte '2.7'

      let(:range) { eval('...5') }

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
      let(:range) { Date.new(2020, 1, 1)..Date.new(2020, 1, 2) }

      it "returns the object hash" do
        is_expected.to eq("min" => Time.utc(2020, 1, 1), "max" => Time.utc(2020, 1, 2))
        expect(subject["min"].utc?).to be(true)
        expect(subject["max"].utc?).to be(true)
      end
    end

    context "given nil" do
      let(:range) { nil }

      it "returns nil" do
        is_expected.to be_nil
      end
    end

    context "given a hash" do
      let(:range) { { 'min' => 1, 'max' => 5, 'exclude_end' => true } }

      it "returns the hash" do
        is_expected.to eq(range)
      end
    end

    context "given a hash missing fields" do
      let(:range) { { 'min' => 1 } }

      it "returns the hash" do
        is_expected.to eq(range)
      end
    end
  end

  describe "#mongoize" do
    subject { range.mongoize }

    context 'given a String' do
      let(:range) { '3' }

      it 'returns a string' do
        is_expected.to eq('3')
      end
    end

    it_behaves_like 'mongoize range'
  end

  describe ".mongoize" do
    subject { Range.mongoize(range) }

    context 'given a String' do
      let(:range) { '3' }

      it "returns nil" do
        is_expected.to be_nil
      end
    end

    context "given a hash with wrong fields" do
      let(:range) { { 'min' => 1, 'max' => 5, 'exclude_end^' => true} }

      it "removes the bogus fields" do
        is_expected.to eq({ 'min' => 1, 'max' => 5 })
      end
    end

    context "given a hash with no correct fields" do
      let(:range) { { 'min^' => 1, 'max^' => 5, 'exclude_end^' => true} }

      it "returns nil" do
        is_expected.to be_nil
      end
    end

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
