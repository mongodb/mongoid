# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Matchable::Not do
  let(:matcher) do
    described_class.new(value)
  end

  let(:match_result) do
    matcher._matches?(query)
  end

  describe "#_matches?" do
    context "when inverting a simple expression" do
      let(:query) do
        {:$eq => "Sir"}
      end

      context "when the inner expression matches" do

        let(:value) do
          'Sir'
        end

        it "returns false" do
          expect(match_result).to be false
        end
      end

      context "when the inner expression does not match" do

        let(:value) do
          'Madam'
        end

        it "returns true" do
          expect(match_result).to be true
        end
      end

      context "when the field is not set" do
        before do
          expect(person.title).to be nil
        end

        it "returns true" do
          expect(match_result).to be true
        end
      end
    end

    context "when inverting a complex expression" do
      let(:query) do
        {:$gt => 50}
      end

      context "when the inner expression matches" do

        let(:value) do
          60
        end

        it "returns false" do
          expect(match_result).to be false
        end
      end

      context "when the inner expression does not match" do

        let(:value) do
          40
        end

        it "returns true" do
          expect(match_result).to be true
        end
      end
    end

    context "when inverting a complex nested expression" do
      shared_examples_for 'negated criterion' do

        context "when the inner expression matches" do

          let(:value) do
            60
          end

          it "returns false" do
            expect(match_result).to be false
          end
        end

        context "when the inner expression does not match" do

          let(:value) do
            40
          end

          it "returns true" do
            expect(match_result).to be true
          end
        end
      end

      context 'with symbol keys' do
        let(:query) do
          {
            :$not => {
              :$not => {
                :age => {
                  :$gt => 50,
                }
              }
            }
          }
        end

        it_behaves_like 'negated criterion'
      end

      context 'with string keys' do
        let(:query) do
          {
            '$not' => {
              '$not' => {
                'age' => {
                  '$gt' => 50,
                }
              }
            }
          }
        end

        it_behaves_like 'negated criterion'
      end
    end
  end
end
