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
        person.age.should be_nil
      end

      it "resets the dirty attributes" do
        person.changes["age"].should be_nil
      end

      it "returns nil" do
        removed.should be_nil
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
          person.age.should be_nil
        end

        it "removes score field" do
          person.score.should be_nil
        end

        it "resets the age dirty attribute" do
          person.changes["age"].should be_nil
        end

        it "resets the score dirty attribute" do
          person.changes["score"].should be_nil
        end

        it "returns nil" do
          removed.should be_nil
        end
      end
    end
  end
end
