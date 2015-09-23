require "spec_helper"

describe Mongoid::Persistable::Incrementable do

  describe "#inc" do

    context "when the document is a root document" do

      shared_examples_for "an incrementable root document" do

        it "increments a positive value" do
          expect(person.age).to eq(15)
        end

        it "decrements a negative value" do
          expect(person.score).to eq(90)
        end

        it "sets a nonexistent value" do
          expect(person.inte).to eq(30)
        end

        it "returns the self document" do
          expect(inc).to eq(person)
        end

        it "persists a positive inc" do
          expect(person.reload.age).to eq(15)
        end

        it "persists a negative inc" do
          expect(person.reload.score).to eq(90)
        end

        it "persists a nonexistent inc" do
          expect(person.reload.inte).to eq(30)
        end

        it "clears out dirty changes" do
          expect(person).to_not be_changed
        end
      end

      let(:person) do
        Person.create(age: 10, score: 100)
      end

      context "when providing string fields" do

        let!(:inc) do
          person.inc("age" => 5, "score" => -10, "inte" => 30)
        end

        it_behaves_like "an incrementable root document"
      end

      context "when providing symbol fields" do

        let!(:inc) do
          person.inc(age: 5, score: -10, inte: 30)
        end

        it_behaves_like "an incrementable root document"
      end

      context "when providing big decimal values" do

        let(:five) do
          BigDecimal.new("5.0")
        end

        let(:neg_ten) do
          BigDecimal.new("-10.0")
        end

        let(:thirty) do
          BigDecimal.new("30.0")
        end

        let!(:inc) do
          person.inc(age: five, score: neg_ten, inte: thirty)
        end

        it_behaves_like "an incrementable root document"
      end
    end

    context "when the document is embedded" do

      shared_examples_for "an incrementable embedded document" do

        it "increments a positive value" do
          expect(address.number).to eq(15)
        end

        it "decrements a negative value" do
          expect(address.no).to eq(90)
        end

        it "sets a nonexistent value" do
          expect(address.house).to eq(30)
        end

        it "returns the self document" do
          expect(inc).to eq(address)
        end

        it "persists a positive inc" do
          expect(address.reload.number).to eq(15)
        end

        it "persists a negative inc" do
          expect(address.reload.no).to eq(90)
        end

        it "persists a nonexistent inc" do
          expect(address.reload.house).to eq(30)
        end

        it "clears out dirty changes" do
          expect(address).to_not be_changed
        end
      end

      let(:person) do
        Person.create
      end

      let(:address) do
        person.addresses.create(street: "test", number: 10, no: 100)
      end

      context "when providing string fields" do

        let!(:inc) do
          address.inc("number" => 5, "no" => -10, "house" => 30)
        end

        it_behaves_like "an incrementable embedded document"
      end

      context "when providing symbol fields" do

        let!(:inc) do
          address.inc(number: 5, no: -10, house: 30)
        end

        it_behaves_like "an incrementable embedded document"
      end

      context "when providing big decimal values" do

        let(:five) do
          BigDecimal.new("5.0")
        end

        let(:neg_ten) do
          BigDecimal.new("-10.0")
        end

        let(:thirty) do
          BigDecimal.new("30.0")
        end

        let!(:inc) do
          address.inc(number: five, no: neg_ten, house: thirty)
        end

        it_behaves_like "an incrementable embedded document"
      end
    end

    context "when the document is embedded in another embedded document" do
      shared_examples_for "an incrementable embedded document in another embedded document" do

        it "increments a positive value" do
          expect(second_answer.position).to eq(2)
        end

        it "persists a positive inc" do
          expect(second_answer.reload.position).to eq(2)
        end

        it "clears out dirty changes" do
          expect(second_answer).to_not be_changed
        end
      end

      let(:survey) do
        Survey.create
      end

      let(:question) do
        survey.questions.create(content: 'foo')
      end

      let!(:first_answer) do
        question.answers.create(position: 99)
      end

      let!(:second_answer) do
        question.answers.create(position: 1)
      end

      context "when providing string fields" do

        let!(:inc) do
          second_answer.inc("position" => 1)
        end

        it_behaves_like "an incrementable embedded document in another embedded document"

      end

      context "when providing symbol fields" do

        let!(:inc) do
          second_answer.inc(position: 1)
        end

        it_behaves_like "an incrementable embedded document in another embedded document"
      end
    end
  end
end
