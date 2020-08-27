# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Atomic::Modifiers do

  let(:modifiers) do
    described_class.new
  end

  describe "#push" do

    context "when the modification is a push with a similar name" do

      let(:pushes) do
        { "addresses.0.locations" => { "street" => "Bond St" } }
      end

      let(:similar1) do
        { "dresses" => { "color" => "red" } }
      end

      let(:similar2) do
        { "ses.0.foo" => { "baz" => "qux" } }
      end

      before do
        modifiers.push(pushes)
        modifiers.push(similar1)
        modifiers.push(similar2)
      end

      it "adds all modifiers to $push" do
        expect(modifiers).to eq({ "$push" => {
                                    "addresses.0.locations" => { '$each' => [{ "street" => "Bond St" }] },
                                    "dresses" => { '$each' => [{ "color" => "red" }] },
                                    "ses.0.foo" => { '$each' => [{ "baz" => "qux" }] }
                                 } })
      end
    end
  end

end
