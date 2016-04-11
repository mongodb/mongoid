require "spec_helper"

describe Mongoid::Refinements do
  using Mongoid::Refinements

  describe ".evolve" do

    context "when provided a regexp" do

      let(:regexp) do
        /^[123]/
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
        "^[123]"
      end

      let(:evolved) do
        Regexp.evolve(regexp)
      end

      it "returns the converted regexp" do
        expect(evolved).to eq(/^[123]/)
      end
    end

    context "when provided an array" do

      context "when the elements are regexps" do

        let(:regexp) do
          /^[123]/
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
          "^[123]"
        end

        let(:evolved) do
          Regexp.evolve([ regexp ])
        end

        it "returns the regexps" do
          expect(evolved).to eq([ /^[123]/ ])
        end
      end
    end
  end

  describe "#regexp?" do

    let(:regexp) do
      /^[123]/
    end

    it "returns true" do
      # Note that you can't rely on Rspec's "be_xx" matcher here.
      # It eventually calls regexp.respond_to?(:regexp), which will return
      # false for the methods defined in Mongoid's Regexp refinement.
      expect(regexp.regexp?).to be(true)
    end
  end
end
