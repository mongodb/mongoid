require "spec_helper"

describe Mongoid::Matchable::Or do

  let(:person) do
    Person.new
  end

  let(:matcher) do
    described_class.new("value", person)
  end

  describe "#matches?" do

    context "when provided a simple expression" do

      context "when any of the values are equal" do

        let(:matches) do
          matcher.matches?(
            [ { title: "Sir" }, { title: "King" } ]
          )
        end

        before do
          person.title = "Sir"
        end

        it "returns true" do
          expect(matches).to be_truthy
        end
      end

      context "when none of the values are equal" do

        it "returns false" do
          expect(matcher.matches?([])).to be_falsey
        end
      end
    end

    context "when provided a complex expression" do

      context "when any of the values are equal" do

        let(:matches) do
          matcher.matches?(
            [
              { title: { "$in" => [ "Sir", "Madam" ] } },
              { title: "King" }
            ]
          )
        end

        before do
          person.title = "Sir"
        end

        it "returns true" do
          expect(matches).to be_truthy
        end
      end

      context "when none of the values are equal" do

        let(:matches) do
          matcher.matches?(
            [
              { title: { "$in" => [ "Prince", "Madam" ] } },
              { title: "King" }
            ]
          )
        end

        before do
          person.title = "Sir"
        end

        it "returns false" do
          expect(matches).to be_falsey
        end
      end

      context "when expression contain multiple fields" do

        let(:matches) do
          matcher.matches?(
            [
              { title: "Sir", age: 23 },
              { title: "King", age: 100 }
            ]
          )
        end

        before do
          person.title = "Sir"
          person.age = 100
        end

        it "returns false" do
          expect(matches).to be_falsey
        end
      end
    end
  end
end
