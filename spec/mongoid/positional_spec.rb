# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Positional do

  describe "#positionally" do

    let(:positionable) do
      Class.new do
        include Mongoid::Positional
      end.new
    end

    let(:updates) do
      {
        "$set" => {
          "field" => "value",
          "children.0.field" => "value",
          "children.0.children.1.children.3.field" => "value"
        },
        "$push" => {
          "children.0.children.1.children.3.fields" => { '$each' => [ "value", "value" ] }
        }
      }
    end

    context "when a child has an embeds many under an embeds one" do

      context "when selector does not include the embeds one" do

        let(:selector) do
          { "_id" => 1, "child._id" => 2 }
        end

        let(:ops) do
          {
            "$set" => {
              "field" => "value",
              "child.children.1.children.3.field" => "value",
            }
          }
        end

        let(:processed) do
          positionable.positionally(selector, ops)
        end

        it "does not do any replacement" do
          expect(processed).to eq(ops)
        end
      end

      context "when selector includes the embeds one" do

        let(:selector) do
          { "_id" => 1, "child._id" => 2, "child.children._id" => 3 }
        end

        let(:ops) do
          {
            "$set" => {
              "field" => "value",
              "child.children.1.children.3.field" => "value",
            }
          }
        end

        let(:expected) do
          {
            "$set" => {
              "field" => "value",
              "child.children.1.children.3.field" => "value",
            }
          }
        end

        let(:processed) do
          positionable.positionally(selector, ops)
        end

        it "does not do any replacement" do
          expect(processed).to eq(expected)
        end
      end
    end

    context "when the selector has only 1 pair" do

      let(:selector) do
        { "_id" => 1 }
      end

      let(:processed) do
        positionable.positionally(selector, updates)
      end

      it "does not do any replacement" do
        expect(processed).to eq(updates)
      end
    end

    context "when the selector has 2 pairs" do

      context "when the second pair has an id" do

        let(:selector) do
          { "_id" => 1, "children._id" => 2 }
        end

        let(:expected) do
          {
            "$set" => {
              "field" => "value",
              "children.$.field" => "value",
              "children.0.children.1.children.3.field" => "value"
            },
            "$push" => {
              "children.0.children.1.children.3.fields" => { '$each' => [ "value", "value" ] }
            }
          }
        end

        let(:processed) do
          positionable.positionally(selector, updates)
        end

        it "replaces the first index with the positional operator" do
          expect(processed).to eq(expected)
        end
      end

      context "when the second pair has no id" do

        let(:selector) do
          { "_id" => 1, "children._id" => nil }
        end

        let(:expected) do
          {
            "$set" => {
              "field" => "value",
              "children.0.field" => "value",
              "children.0.children.1.children.3.field" => "value"
            },
            "$push" => {
              "children.0.children.1.children.3.fields" => { '$each' => [ "value", "value" ] }
            }
          }
        end

        let(:processed) do
          positionable.positionally(selector, updates)
        end

        it "does not replace the index with the positional operator" do
          expect(processed).to eq(expected)
        end
      end
    end

    context "when the selector has 3 pairs" do

      let(:selector) do
        { "_id" => 1, "children._id" => 2, "children.0.children._id" => 3 }
      end

      let(:expected) do
        {
          "$set" => {
            "field" => "value",
            "children.$.field" => "value",
            "children.0.children.1.children.3.field" => "value"
          },
          "$push" => {
            "children.0.children.1.children.3.fields" => { '$each' => [ "value", "value" ] }
          }
        }
      end

      let(:processed) do
        positionable.positionally(selector, updates)
      end

      it "replaces the first index with the positional operator" do
        expect(processed).to eq(expected)
      end
    end

    context "when the selector has 4 pairs" do

      let(:selector) do
        {
          "_id" => 1,
          "children._id" => 2,
          "children.0.children._id" => 3,
          "children.0.children.1.children._id" => 4
        }
      end

      let(:expected) do
        {
          "$set" => {
            "field" => "value",
            "children.$.field" => "value",
            "children.0.children.1.children.3.field" => "value"
          },
          "$push" => {
            "children.0.children.1.children.3.fields" => { '$each' => [ "value", "value" ] }
          }
        }
      end

      let(:processed) do
        positionable.positionally(selector, updates)
      end

      it "replaces the first index with the positional operator" do
        expect(processed).to eq(expected)
      end
    end
  end
end
