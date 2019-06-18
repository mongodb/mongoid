# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Association::Embedded::EmbeddedIn::Buildable do

  describe "#build" do

    let(:base) do
      double
    end

    let(:options) do
      { }
    end

    let(:association) do
      Mongoid::Association::Embedded::EmbeddedIn.new(Person, :addresses, options)
    end

    context "when a document is provided" do

      let(:object) do
        double
      end

      let(:document) do
        association.build(base, object)
      end

      it "returns the document" do
        expect(document).to eq(object)
      end
    end
  end
end
