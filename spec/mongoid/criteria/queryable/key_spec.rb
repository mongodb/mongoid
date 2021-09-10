# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Criteria::Queryable::Key do

  describe "#initialize" do

    let(:key) do
      described_class.new("field", :__union__, "$all")
    end

    it "sets the name" do
      expect(key.name).to eq("field")
    end

    it "sets the operator" do
      expect(key.operator).to eq("$all")
    end

    it "sets the strategy" do
      expect(key.strategy).to eq(:__union__)
    end
  end

  describe "#__expr_part__" do

    context 'operator only' do
      let(:key) do
        described_class.new("field", :__union__, "$all")
      end

      let(:specified) do
        key.__expr_part__([ 1, 2 ])
      end

      it "returns the name plus operator and value" do
        expect(specified).to eq({ "field" => { "$all" => [ 1, 2 ] }})
      end
    end

    context 'operator and expanded only' do
      let(:key) do
        described_class.new("field", :__override__, "$geoIntersects", '$geometry')
      end

      let(:specified) do
        key.__expr_part__([ 1, 10 ])
      end

      it "returns the query expression" do
        expect(specified).to eq({ "field" => {
          '$geoIntersects' => {
            '$geometry' => [1, 10],
          },
        }})
      end
    end

    context 'operator, expanded and block' do
      let(:key) do
        described_class.new("field", :__override__, "$geoIntersects", '$geometry') do |value|
          { "type" => 'Point', "coordinates" => value }
        end
      end

      let(:specified) do
        key.__expr_part__([ 1, 10 ])
      end

      it "returns the query expression" do
        expect(specified).to eq({ "field" => {
          '$geoIntersects' => {
            '$geometry' => {
              'type' => 'Point', 'coordinates' => [1, 10],
            },
          },
        }})
      end
    end
  end

  describe '#hash' do
    let(:key) do
      described_class.new("field", :__union__, "$all")
    end

    let(:other) do
      described_class.new("field", :__union__, "$all")
    end

    it "returns the same hash for keys with the same attributes" do
      expect(key.hash).to eq(other.hash)
    end
  end
end
