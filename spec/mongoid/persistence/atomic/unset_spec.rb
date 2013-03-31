require "spec_helper"

describe Mongoid::Persistence::Atomic::Unset do

  describe "#persist" do

    context "when unsetting a field" do

      let(:person) do
        Person.create(age: 100)
      end

      let!(:removed) do
        person.unset(:age)
      end

      it "removes the field" do
        expect(person.age).to be_nil
      end

      it "resets the dirty attributes" do
        expect(person.changes["age"]).to be_nil
      end

      it "returns nil" do
        expect(removed).to be_nil
      end
    end


    [[ :age, :score, { safe: true }], [ :age, :score ], [ [:age, :score ]]].each do |args|

      context "when unsetting multiple fields using #{args}" do

        let(:person) do
          Person.create(age: 100, score: 2)
        end

        let!(:removed) do
          person.unset *(args)
        end

        it "removes age field" do
          expect(person.age).to be_nil
        end

        it "removes score field" do
          expect(person.score).to be_nil
        end

        it "resets the age dirty attribute" do
          expect(person.changes["age"]).to be_nil
        end

        it "resets the score dirty attribute" do
          expect(person.changes["score"]).to be_nil
        end

        it "returns nil" do
          expect(removed).to be_nil
        end
      end
    end
  end
end
