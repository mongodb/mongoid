require "spec_helper"

describe Mongoid::Matchable::And do

  let(:person) do
    Person.new
  end

  let(:matcher) do
    described_class.new("value", person)
  end

  describe "#matches?" do

    context "when provided a simple expression" do

      context "when only one expression provided" do

        context "when the value matches" do

          let(:matches) do
            matcher.matches?([ { title: "Sir" } ])
          end

          before do
            person.title = "Sir"
          end

          it "returns true" do
            expect(matches).to be true
          end
        end

        context "when the expression is a $not" do

          let(:matches) do
            matcher.matches?([ { title: {:$not => /Foobar/ } }])
          end

          context "when the value matches" do

            it "returns true" do
              expect(matches).to be true
            end
          end

          context "when the value does not match" do

            before do
              person.title = "Foobar baz"
            end

            it "returns false" do
              expect(matches).to be false
            end
          end
        end

        context "when the value does not match" do

          let(:matches) do
            matcher.matches?([ { title: "Sir" } ])
          end

          it "returns false" do
            expect(matches).to be false
          end
        end
      end

      context "when multiple expressions provided" do

        context "when all of the values are equal" do

          let(:matches) do
            matcher.matches?(
              [ { title: "Sir" }, { _id: person.id } ]
            )
          end

          before do
            person.title = "Sir"
          end

          it "returns true" do
            expect(matches).to be true
          end
        end

        context "when one of the values does not match" do

          let(:matches) do
            matcher.matches?(
              [ { title: "Sir" }, { _id: BSON::ObjectId.new } ]
            )
          end

          before do
            person.title = "Sir"
          end

          it "returns false" do
            expect(matches).to be false
          end
        end

        context "when provided no expressions" do

          let(:matches) do
            matcher.matches?([])
          end

          it "returns true" do
            expect(matches).to be true
          end
        end
      end
    end

    context "when provided a complex expression" do

      context "when all of the values are equal" do

        let(:matches) do
          matcher.matches?(
            [
              { title: { "$in" => [ "Sir", "Madam" ] } },
              { _id: person.id }
            ]
          )
        end

        before do
          person.title = "Sir"
        end

        it "returns true" do
          expect(matches).to be true
        end
      end

      context "when one of the values does not match" do

        let(:matches) do
          matcher.matches?(
            [
              { title: { "$in" => [ "Prince", "Madam" ] } },
              { _id: BSON::ObjectId.new }
            ]
          )
        end

        before do
          person.title = "Sir"
        end

        it "returns false" do
          expect(matches).to be false
        end
      end

      context "when expression contain multiple fields" do

        context "when all the expressions match" do

          let(:matches) do
            matcher.matches?(
              [
                { title: "Sir", age: 23 },
                { _id: person.id }
              ]
            )
          end

          before do
            person.title = "Sir"
            person.age = 23
          end

          it "returns true" do
            expect(matches).to be true
          end
        end
      end
    end
  end
end
