# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Criteria::Queryable::Extensions::Regexp::Raw_ do

  describe ".evolve" do

    context "when provided a bson raw regexp" do

      let(:regexp) do
        BSON::Regexp::Raw.new("^[123]")
      end

      let(:evolved) do
        BSON::Regexp::Raw.evolve(regexp)
      end

      it "returns the regexp" do
        expect(evolved).to be(regexp)
      end
    end

    context "when providing a string" do

      let(:regexp_string) do
        '^[123]'
      end

      let(:evolved) do
        BSON::Regexp::Raw.evolve(regexp_string)
      end

      it "returns the converted raw regexp" do
        expect(evolved).to eq(BSON::Regexp::Raw.new(regexp_string))
      end
    end

    context "when provided an array" do

      context "when the elements are bson raw regexps" do

        let(:regexp) do
          BSON::Regexp::Raw.new("^[123]")
        end

        let(:array) do
          [ regexp ]
        end

        let(:evolved) do
          BSON::Regexp::Raw.evolve(array)
        end

        it "returns the array containing raw regexps" do
          expect(evolved).to eq([ regexp ])
        end

        it "does not evolve in place" do
          expect(evolved).to_not equal(array)
        end
      end

      context "when the elements are strings" do

        let(:regexp_string) do
          "^[123]"
        end

        let(:evolved) do
          BSON::Regexp::Raw.evolve([ regexp_string ])
        end

        it "returns the regexps" do
          expect(evolved).to eq([ BSON::Regexp::Raw.new(regexp_string) ])
        end
      end
    end
  end

  describe "#regexp?" do

    let(:regexp) do
      BSON::Regexp::Raw.new('^[123]')
    end

    it "returns true" do
      expect(regexp).to be_regexp
    end
  end
end
