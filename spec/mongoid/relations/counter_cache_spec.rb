require "spec_helper"

describe Mongoid::Relations::CounterCache do

  describe "#reset_counters" do

    context "when counter is reset" do

      let(:person) do
        Person.create do |person|
          person[:drugs_count] = 3
        end
      end

      before do
        Person.reset_counters person.id, :drugs
      end

      it "returns zero" do
        expect(person.reload.drugs_count).to eq(0)
      end
    end

    context "when counter is reset with wrong id" do

      it "expect to raise an error" do
        expect {
          Person.reset_counters "1", :drugs
        }.to raise_error
      end
    end

    context "when reset with invalid name" do

      let(:person) do
        Person.create
      end

      it "expect to raise an error" do
        expect {
          Person.reset_counters person.id, :not_exist
        }.to raise_error
      end
    end

    context "when counter gets messy" do

      let(:person) do
        Person.create
      end

      let!(:post) do
        person.posts.create(title: "my first post")
      end

      before do
        Person.update_counters(person.id, :posts_count => 10)
        Person.reset_counters(person.id, :posts)
      end

      it "resets to the right value" do
        expect(person.reload.posts_count).to eq(1)
      end
    end

    context "when the counter is on a subclass" do

      let(:subscription) do
        Subscription.create
      end

      let!(:pack) do
        subscription.packs.create
      end

      before do
        Subscription.reset_counters(subscription.id, :packs)
      end

      it "resets the appropriate counter" do
        expect(subscription.reload[:packs_count]).to eq(1)
      end
    end
  end

  describe "#update_counters" do

    context "when was 3 " do

      let(:person) do
        Person.create do |person|
          person[:drugs_count] = 3
        end
      end

      context "and update counter with 5" do

        before do
          Person.update_counters person.id, :drugs_count => 5
        end

        it "return 8" do
          expect(person.reload.drugs_count).to eq(8)
        end
      end

      context "and update counter with -5" do

        before do
          Person.update_counters person.id, :drugs_count => -5
        end

        it "return -2" do
          expect(person.reload.drugs_count).to eq(-2)
        end
      end
    end
    context "when update with 2 and use a string argument" do

      let(:person) { Person.create }

      before do
        Person.update_counters person.id, "drugs_count" => 2
      end

      it "returns 2" do
        expect(person.reload.drugs_count).to eq(2)
      end
    end

    context "when update more multiple counters" do

      let(:person) { Person.create }

      before do
        Person.update_counters(person.id, :drugs_count => 2, :second_counter => 5)
      end

      it "updates drugs_counter" do
        expect(person.reload.drugs_count).to eq(2)
      end

      it "updates second_counter" do
        expect(person.reload.second_counter).to eq(5)
      end
    end
  end

  describe "#increment_counter" do

    let(:person) { Person.create }

    context "when increment 3 times" do

      before do
        3.times { Person.increment_counter(:drugs_count, person.id) }
      end

      it "returns 3" do
        expect(person.reload.drugs_count).to eq(3)
      end
    end

    context "when increment 3 times using string as argument" do

      before do
        3.times { Person.increment_counter("drugs_count", person.id) }
      end

      it "returns 3" do
        expect(person.reload.drugs_count).to eq(3)
      end
    end
  end

  describe "#decrement_counter" do

    let(:person) do
      Person.create do |p|
        p[:drugs_count] = 3
      end
    end

    context "when decrement 3 times" do

      before do
        3.times { Person.decrement_counter(:drugs_count, person.id) }
      end

      it "returns 0" do
        expect(person.reload.drugs_count).to eq(0)
      end
    end
    context "when increment 3 times using string as argument" do

      before do
        3.times { Person.decrement_counter("drugs_count", person.id) }
      end

      it "returns 0" do
        expect(person.reload.drugs_count).to eq(0)
      end
    end
  end
end
