# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Association::Embedded::EmbedsMany::Buildable do

  let(:base) do
    double
  end

  let(:options) do
    { }
  end

  describe "#build" do

    let(:documents) do
      association.build(base, object)
    end

    let(:association) do
      Mongoid::Association::Embedded::EmbedsMany.new(Person, :addresses, options)
    end

    context "when passed an array of documents" do

      let(:object) do
        [ Address.new(city: "London") ]
      end

      it "returns an array of documents" do
        expect(documents).to eq(object)
      end
    end

    context "when the array is empty" do

      let(:object) do
        []
      end

      it "returns an empty array" do
        expect(documents).to eq(object)
      end
    end

    context "when passed nil" do

      let(:object) do
        nil
      end

      it "returns an empty array" do
        expect(documents).to be_empty
      end
    end

    context "when no type is in the object" do

      let(:object) do
        [ { "city" => "London" }, { "city" => "Shanghai" } ]
      end

      it "returns an array of documents" do
        expect(documents).to be_a_kind_of(Array)
      end

      it "creates the correct type of documents" do
        expect(documents[0]).to be_a_kind_of(Address)
      end

      it "sets the object on the documents" do
        expect(documents[0].city).to eq("London")
        expect(documents[1].city).to eq("Shanghai")
      end
    end

    context "when a type is in the object" do

      let(:association) do
        Mongoid::Association::Embedded::EmbedsMany.new(Person, :shapes)
      end

      let(:object) do
        [
            { "_type" => "Circle", "radius" => 100 },
            { "_type" => "Square", "width" => 50 }
        ]
      end

      it "returns an array of documents" do
        expect(documents).to be_a_kind_of(Array)
      end

      it "creates the correct type of document" do
        expect(documents[0]).to be_a_kind_of(Circle)
        expect(documents[1]).to be_a_kind_of(Square)
      end

      it "sets the object on the document" do
        expect(documents[0].radius).to eq(100)
        expect(documents[1].width).to eq(50)
      end
    end
  end
end
