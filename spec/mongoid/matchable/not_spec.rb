# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Matchable::Not do
  let(:person) do
    Person.new
  end

  let(:matcher) do
    described_class.new("value", person)
  end

  describe "#_matches?" do
    context "when inverting a simple expression" do
      let(:matches) do
        query = {
          :title => {
            :$not => {:$eq => "Sir"}
          }
        }
        matcher._matches?(query)
      end

      context "when the inner expression matches" do
        before do
          person.title = "Sir"
        end

        it "returns false" do
          expect(matches).to be false
        end
      end

      context "when the inner expression does not match" do
        before do
          person.title = "Madam"
        end

        it "returns true" do
          expect(matches).to be true
        end
      end
    end

    context "when inverting a complex expression" do
      let(:matches) do
        query = {
          :age => {
            :$not => {:$gt => 50}
          }
        }
        matcher._matches?(query)
      end

      context "when the inner expression matches" do
        before do
          person.age = 60
        end

        it "returns false" do
          expect(matches).to be false
        end
      end

      context "when the inner expression does not match" do
        before do
          person.age = 40
        end

        it "returns true" do
          expect(matches).to be true
        end
      end
    end

    context "when inverting a complex nested expression" do
      let(:matches) do
        query = {
          :not => {
            :$not => {
              :$not => {
                :age => {
                  :$gt => 50
                }
              }
            }
          }
        }
        matcher._matches?(query)
      end

      context "when the inner expression matches" do
        before do
          person.age = 60
        end

        it "returns false" do
          expect(matches).to be false
        end
      end

      context "when the inner expression does not match" do
        before do
          person.age = 40
        end

        it "returns true" do
          expect(matches).to be true
        end
      end
    end
  end
end
