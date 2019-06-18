# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Matchable::Nor do

  let(:target) do
    Person.new
  end

  let(:matcher) do
    described_class.new("value", target)
  end

  describe "#_matches?" do

    context "when provided a simple expression" do

      context "when one of the hashes does not match model" do

        let(:matches) do
          matcher._matches?(
            [ { title: "Sir" }, { title: "King" } ]
          )
        end

        let(:target) do
          Person.new(title: 'Queen')
        end

        it "returns true" do
          expect(matches).to be true
        end
      end

      context "when all of the hashes match different fields in model" do
        let(:matches) do
          matcher._matches?(
            [ { age: 10 }, { title: "King" } ]
          )
        end

        let(:target) do
          Person.new(title: 'King', age: 10)
        end

        it "returns false" do
          expect(matches).to be false
        end
      end

      context "when one of the hashes matches an array field in model" do
        let(:matches) do
          matcher._matches?(
            [ { af: "Sir" }, { af: "King" } ]
          )
        end

        let(:target) do
          ArrayField.new(af: ['King'])
        end

        it "returns false" do
          expect(matches).to be false
        end
      end

      context "when none of the hashes matches an array field in model" do
        let(:matches) do
          matcher._matches?(
            [ { af: "Sir" }, { af: "King" } ]
          )
        end

        let(:target) do
          ArrayField.new(af: ['Boo'])
        end

        it "returns true" do
          expect(matches).to be true
        end
      end

      context "when there are no criteria" do

        it "returns false" do
          expect(matcher._matches?([])).to be false
        end
      end

      # $nor with $not is a double negation.
      # Whatever the argument of $not is is what the overall condition
      # is looking for.
      context "when the expression is a $not" do

        let(:matches) do
          matcher._matches?([ { title: {:$not => /Foobar/ } }])
        end

        context "when the value does not match $not argument" do

          let(:target) do
            Person.new(title: 'test')
          end

          it "returns false" do
            expect(matches).to be false
          end
        end

        context "when the value matches $not argument" do

          let(:target) do
            Person.new(title: 'Foobar baz')
          end

          it "returns true" do
            expect(matches).to be true
          end
        end
      end
    end

    context "when provided a complex expression" do

      context "when none of the model values match criteria values" do

        let(:matches) do
          matcher._matches?(
            [
              { title: { "$in" => [ "Sir", "Madam" ] } },
              { title: "King" }
            ]
          )
        end

        let(:target) do
          Person.new(title: 'Queen')
        end

        it "returns true" do
          expect(matches).to be true
        end
      end

      context "when there is a matching value" do

        let(:matches) do
          matcher._matches?(
            [
              { title: { "$in" => [ "Prince", "Madam" ] } },
              { title: "King" }
            ]
          )
        end

        let(:target) do
          Person.new(title: 'Prince')
        end

        it "returns false" do
          expect(matches).to be false
        end
      end

      context "when expression contain multiple fields" do

        let(:matches) do
          matcher._matches?(
            [
              { title: "Sir", age: 23 },
              { title: "King", age: 100 }
            ]
          )
        end

        context 'and model has different values in all of the fields' do
          let(:target) do
            Person.new(title: 'Queen', age: 10)
          end

          it "returns true" do
            expect(matches).to be true
          end
        end

        context 'and model has identical value in one of the fields' do
          let(:target) do
            Person.new(title: 'Queen', age: 23)
          end

          it "returns true" do
            expect(matches).to be true
          end
        end

        context 'and model has identical values in all of the fields' do
          let(:target) do
            Person.new(title: 'Sir', age: 23)
          end

          it "returns false" do
            expect(matches).to be false
          end
        end
      end
    end
  end
end
