# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Association::Referenced::CounterCache do

  describe "#reset_counters" do

    context "when counter is reset" do

      let(:person) do
        Person.create! do |person|
          person[:drugs_count] = 3
        end
      end

      before do
        person.reset_counters(:drugs)
      end

      it "sets the counter to zero" do
        expect(person.drugs_count).to eq(0)
      end

      it "persists the changes" do
        expect(person.reload.drugs_count).to eq(0)
      end
    end

    context "when reset with invalid name" do

      let(:person) do
        Person.create!
      end

      it "expect to raise an error" do
        expect {
          person.reset_counters(:not_exist)
        }.to raise_error(NoMethodError)
      end
    end

    context "when counter gets messy" do

      let(:person) do
        Person.create!
      end

      let!(:post) do
        person.posts.create!(title: "my first post")
      end

      before do
        Person.update_counters(person.id, :posts_count => 10)
        person.reload
        person.reset_counters(:posts)
      end

      it "resets to the right value" do
        expect(person.posts_count).to eq(1)
      end

      it "persists the change" do
        expect(person.reload.posts_count).to eq(1)
      end
    end

    context "when the counter is on a subclass" do

      let(:subscription) do
        Subscription.create!
      end

      let!(:pack) do
        subscription.packs.create!
      end

      before do
        subscription.reset_counters(:packs)
      end

      it "resets the appropriate counter" do
        expect(subscription[:packs_count]).to eq(1)
      end

      it "persists the change" do
        expect(subscription.reload[:packs_count]).to eq(1)
      end
    end

    context 'when there are persistence options set' do

      let(:subscription) do
        Subscription.new
      end

      before do
        subscription.with(collection: 'other') do |sub|
          sub.save!
          sub.packs.create!
        end
      end

      it 'applies the persistence options when resetting the counter' do
        subscription.with(collection: 'other') do |sub|
          expect(sub.reload[:packs_count]).to eq(1)
        end
      end
    end
  end

  describe ".reset_counters" do

    context "when counter is reset" do

      let(:person) do
        Person.create! do |person|
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
        }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class Person with id\(s\)/)
      end
    end

    context "when reset with invalid name" do

      let(:person) do
        Person.create!
      end

      it "expect to raise an error" do
        expect {
          Person.reset_counters person.id, :not_exist
        }.to raise_error(NoMethodError)
      end
    end

    context "when counter gets messy" do

      let(:person) do
        Person.create!
      end

      let!(:post) do
        person.posts.create!(title: "my first post")
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
        Subscription.create!
      end

      let!(:pack) do
        subscription.packs.create!
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
        Person.create! do |person|
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

      let(:person) { Person.create! }

      before do
        Person.update_counters person.id, "drugs_count" => 2
      end

      it "returns 2" do
        expect(person.reload.drugs_count).to eq(2)
      end
    end

    context "when update more multiple counters" do

      let(:person) { Person.create! }

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

    let(:person) { Person.create! }

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

    context 'when there are persistence options set' do

      let(:person) do
        Person.new
      end

      before do
        person.with(collection: 'other') do |per|
          per.save!
          per.drugs.create!
        end
      end

      it 'applies the persistence options when resetting the counter' do
        person.with(collection: 'other') do |per|
          expect(per.drugs_count).to eq(1)
        end
      end
    end
  end

  describe "#decrement_counter" do

    let(:person) do
      Person.create! do |p|
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

    context 'when there are persistence options set' do

      let(:person) do
        Person.new
      end

      before do
        person.with(collection: 'other') do |per|
          per.save!
          drug = per.drugs.create!
          drug.destroy
        end
      end

      it 'applies the persistence options when resetting the counter' do
        person.with(collection: 'other') do |per|
          expect(per.reload.drugs_count).to eq(0)
        end
      end
    end
  end

  describe "#add_counter_cache_callbacks" do

    context "when parent is not frozen" do

      context 'when #destroy is called on the object' do

        let(:person) do
          Person.create!
        end

        let!(:drug) do
          person.drugs.create!
        end

        before do
          drug.destroy
        end

        it "updates the counter cache" do
          expect(person.drugs_count).to eq(0)
        end
      end

      context 'when #create is called on the object' do

        let(:person) do
          Person.create! { |p| p.drugs += [Drug.create!, Drug.create!] }
        end

        it "updates the counter cache" do
          expect(person.drugs_count).to eq(2)
        end
      end

      context 'when #update is called on the object' do

        let(:person1) do
          Person.create! { |p| p.drugs += [Drug.create!, Drug.create!] }
        end

        let(:drug) do
          person1.drugs.first
        end

        let(:person2) do
          Person.create!
        end

        before do
          drug.update_attribute(:person, person2)
        end

        it "updates the current counter cache" do
          expect(drug.person.drugs_count).to eq(1)
        end

        it "updates the current counter cache" do
          expect(person2.drugs_count).to eq(1)
        end

        it "updates the original object's counter cache" do
          expect(person1.reload.drugs_count).to eq(1)
        end

        context 'when foreign_key differs from model name' do

          let(:genre) { PostGenre.create! }

          let(:post) { Post.create! }

          it 'updates correct counter cache' do
            post.update post_genre: genre
            expect(genre.reload.posts_count).to eq 1
          end
        end
      end
    end

    context "when parent is frozen" do

      let(:person) do
        Person.create!
      end

      let!(:drug) do
        person.drugs.create!
      end

      before do
        person.destroy
        drug.destroy
      end

      it "before_destroy doesn't update counter cache" do
        expect(person.drugs_count).to eq(1)
      end
    end
  end
end
