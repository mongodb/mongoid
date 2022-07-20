# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Boolean do

  [ :mongoize, :demongoize ].each do |method|

    describe ".#{method}" do

      context "when provided a boolean" do

        context "when provided true" do

          it "returns true" do
            expect(described_class.send(method, true)).to eq(true)
          end
        end

        context "when provided false" do

          it "returns false" do
            expect(described_class.send(method, false)).to eq(false)
          end
        end
      end

      context "when provided a string" do

        context "when provided true" do

          it "returns true" do
            expect(described_class.send(method, "true")).to eq(true)
          end
        end

        context "when provided t" do

          it "returns true" do
            expect(described_class.send(method, "t")).to eq(true)
          end
        end

        context "when provided 1" do

          it "returns true" do
            expect(described_class.send(method, "1")).to eq(true)
          end
        end

        context "when provided 1.0" do

          it "returns true" do
            expect(described_class.send(method, "1.0")).to eq(true)
          end
        end

        context "when provided yes" do

          it "returns true" do
            expect(described_class.send(method, "yes")).to eq(true)
          end
        end

        context "when provided y" do

          it "returns true" do
            expect(described_class.send(method, "y")).to eq(true)
          end
        end

        context "when provided on" do

          it "returns true" do
            expect(described_class.send(method, "on")).to eq(true)
          end
        end

        context "when provided false" do

          it "returns false" do
            expect(described_class.send(method, "false")).to eq(false)
          end
        end

        context "when provided f" do

          it "returns false" do
            expect(described_class.send(method, "f")).to eq(false)
          end
        end

        context "when provided 0" do

          it "returns false" do
            expect(described_class.send(method, "0")).to eq(false)
          end
        end

        context "when provided 0.0" do

          it "returns false" do
            expect(described_class.send(method, "0.0")).to eq(false)
          end
        end

        context "when provided no" do

          it "returns false" do
            expect(described_class.send(method, "no")).to eq(false)
          end
        end

        context "when provided n" do

          it "returns false" do
            expect(described_class.send(method, "n")).to eq(false)
          end
        end

        context "when provided off" do

          it "returns true" do
            expect(described_class.send(method, "off")).to eq(false)
          end
        end
      end
    end
  end

  describe "#mongoize" do

    it "returns self" do
      expect(true.mongoize).to eq(true)
    end
  end
end
