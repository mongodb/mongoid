# frozen_string_literal: true

require "spec_helper"


describe Mongoid::Criteria::Queryable::Extensions::Regexp do

  describe ".evolve" do

    context "when provided a regexp" do

      let(:regexp) do
        /\A[123]/
      end

      let(:evolved) do
        Regexp.evolve(regexp)
      end

      it "returns the regexp" do
        expect(evolved).to eq(regexp)
      end
    end

    context "when provided a string" do

      let(:regexp) do
        "\\A[123]"
      end

      let(:evolved) do
        Regexp.evolve(regexp)
      end

      it "returns the converted regexp" do
        expect(evolved).to eq(/\A[123]/)
      end
    end

    context "when provided an array" do

      context "when the elements are regexps" do

        let(:regexp) do
          /\A[123]/
        end

        let(:array) do
          [ regexp ]
        end

        let(:evolved) do
          Regexp.evolve(array)
        end

        it "returns the regexps" do
          expect(evolved).to eq([ regexp ])
        end

        it "does not evolve in place" do
          expect(evolved).to_not equal(array)
        end
      end

      context "when the elements are strings" do

        let(:regexp) do
          "\\A[123]"
        end

        let(:evolved) do
          Regexp.evolve([ regexp ])
        end

        it "returns the regexps" do
          expect(evolved).to eq([ /\A[123]/ ])
        end
      end
    end
  end

  describe "#regexp?" do

    let(:regexp) do
      /\A[123]/
    end

    it "returns true" do
      expect(regexp).to be_regexp
    end
  end
end
