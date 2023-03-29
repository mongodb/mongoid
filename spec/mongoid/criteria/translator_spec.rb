# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Criteria::Translator do
  describe "#to_direction" do
    context "when the value is a string" do
      context "when ascending" do
        it "returns 1" do
          expect(described_class.to_direction("ascending")).to eq(1)
        end
      end

      context "when asc" do
        it "returns 1" do
          expect(described_class.to_direction("asc")).to eq(1)
        end
      end

      context "when ASCENDING" do
        it "returns 1" do
          expect(described_class.to_direction("ASCENDING")).to eq(1)
        end
      end

      context "when ASC" do
        it "returns 1" do
          expect(described_class.to_direction("ASC")).to eq(1)
        end
      end

      context "when descending" do
        it "returns -1" do
          expect(described_class.to_direction("descending")).to eq(-1)
        end
      end

      context "when desc" do
        it "returns -1" do
          expect(described_class.to_direction("desc")).to eq(-1)
        end
      end

      context "when DESCENDING" do
        it "returns -1" do
          expect(described_class.to_direction("DESCENDING")).to eq(-1)
        end
      end

      context "when DESC" do
        it "returns -1" do
          expect(described_class.to_direction("DESC")).to eq(-1)
        end
      end
    end

    context "when the value is a symbol" do
      context "when ascending" do
        it "returns 1" do
          expect(described_class.to_direction(:ascending)).to eq(1)
        end
      end
  
      context "when asc" do
        it "returns 1" do
          expect(described_class.to_direction(:asc)).to eq(1)
        end
      end
  
      context "when ASCENDING" do
        it "returns 1" do
          expect(described_class.to_direction(:ASCENDING)).to eq(1)
        end
      end
  
      context "when ASC" do
        it "returns 1" do
          expect(described_class.to_direction(:ASC)).to eq(1)
        end
      end
  
      context "when descending" do
        it "returns -1" do
          expect(described_class.to_direction(:descending)).to eq(-1)
        end
      end
  
      context "when desc" do
        it "returns -1" do
          expect(described_class.to_direction(:desc)).to eq(-1)
        end
      end
  
      context "when DESCENDING" do
        it "returns -1" do
          expect(described_class.to_direction(:DESCENDING)).to eq(-1)
        end
      end
  
      context "when DESC" do
        it "returns -1" do
          expect(described_class.to_direction(:DESC)).to eq(-1)
        end
      end
    end

    context "when the value is numeric" do
      it "should pass the value through unchanged" do
        expect(described_class.to_direction(1)).to eq(1)
        expect(described_class.to_direction(-1)).to eq(-1)
        expect(described_class.to_direction(Math::PI)).to eq(Math::PI)
      end
    end

    context "when the value is a hash" do
      it "should pass the value through unchanged" do
        expect(described_class.to_direction({})).to eq({})
        expect(described_class.to_direction(scope: { "$meta" => "textScore" }))
          .to eq(scope: { "$meta" => "textScore" })
        expect(described_class.to_direction(a: 1, b: 2)).to eq(a: 1, b: 2)
      end
    end

    context "when the value is an unrecognized type" do
      it "should raise ArgumentError" do
        expect { described_class.to_direction([]) }.to raise_error(ArgumentError)
        expect { described_class.to_direction(/a/) }.to raise_error(ArgumentError)
        expect { described_class.to_direction(Object.new) }.to raise_error(ArgumentError)
      end
    end
  end
end
