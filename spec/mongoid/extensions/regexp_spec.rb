# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Extensions::Regexp do

  [ :mongoize, :demongoize ].each do |method|

    describe ".#{method}" do

      context "when providing a regex" do

        let(:value) do
          Regexp.send(method, /[^abc]/)
        end

        it "returns the provided value" do
          expect(value).to eq(/[^abc]/)
        end
      end

      context "when providing a string" do

        let(:value) do
          Regexp.send(method, "[^abc]")
        end

        it "returns the provided value as a regex" do
          expect(value).to eq(/[^abc]/)
        end


        context "when the string is empty" do

          let(:value) do
            Regexp.send(method, "")
          end

          it "returns an empty regex" do
            expect(value).to eq(//)
          end
        end
      end

      context "when the value is nil" do

        let(:value) do
          Regexp.send(method, nil)
        end

        it "returns the nil" do
          expect(value).to be_nil
        end
      end

      context "when providing a BSON::Regexp::Raw" do

        let(:value) do
          Regexp.send(method, BSON::Regexp::Raw.new("hello"))
        end

        it "returns a Regexp" do
          expect(value).to eq(/hello/)
        end
      end

      context "when providing an invalid regexp" do

        let(:value) do
          Regexp.send(method, "[")
        end

        it "returns nil" do
          expect(value).to be_nil
        end
      end

      context "when providing an invalid Regexp to a BSON::Regexp::Raw" do

        let(:value) do
          Regexp.send(method, BSON::Regexp::Raw.new("["))
        end

        it "returns nil" do
          expect(value).to be_nil
        end
      end
    end
  end

  describe "#mongoize" do

    it "returns self" do
      expect(/[^abc]/.mongoize).to eq(/[^abc]/)
    end
  end
end
