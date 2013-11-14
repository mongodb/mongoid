require "spec_helper"

describe Mongoid::Relations::Synchronization do

  before(:all) do
    Mongoid.raise_not_found_error = true
    Person.synced(Person.relations["preferences"])
  end

  after(:all) do
    Person.reset_callbacks(:save)
    Person.reset_callbacks(:destroy)
  end

  describe ".update_inverse_keys" do

    let(:agent) do
      Agent.create!
    end

    let(:user) do
      User.create!
    end

    let(:person) do
      Person.create!
    end

    context "when an unpersisted account is created" do

      let(:account) do
        Account.new do |a|
          a.name = "testing"
          a.creator = user
          a.person = person
        end
      end

      it "has persisted :agent" do
        expect(agent.persisted?).to be true
      end

      it "has persisted :user" do
        expect(user.persisted?).to be true
      end

      it "has persisted :person" do
        expect(person.persisted?).to be true
      end

      it "does not have persisted :account" do
        expect(account.persisted?).to be false
      end

      it "has instantiated a .valid? :account" do
        account.valid?
        expect(account.valid?).to be true
      end

      context "and is Persisted" do

        it "is able to :save" do
          expect(account.save).to be true
        end
      end

      context "check for existing Agent, then Persisted" do

        before do
          account.agents.where(_id: agent.id).exists?
        end

        it "is able to :save" do
          expect(account.save).to be true
        end
      end
    end
  end

  context "when the inverse of is nil" do

    let(:preference) do
      Preference.new(name: "test")
    end

    let(:article) do
      Article.new
    end

    before do
      article.preferences << preference
    end

    it "does not attempt synchronization" do
      expect { article.save }.to_not raise_error
    end

    it "sets the one side of the relation" do
      expect(article.preferences).to eq([ preference ])
    end
  end

  context "when first setting by the relation itself" do

    let!(:person) do
      Person.create
    end

    let!(:one) do
      Preference.create(name: "one")
    end

    before do
      person.preferences << one
    end

    it "sets the inverse foreign key" do
      expect(one.person_ids).to eq([ person.id ])
    end

    it "resets the synced flag" do
      expect(person.synced["preference_ids"]).to be false
    end

    context "when subsequently setting with keys" do

      let!(:two) do
        Preference.create(name: "two")
      end

      before do
        person.preference_ids << two.id
        person.save
      end

      it "sets the inverse foreign key" do
        expect(two.reload.person_ids).to eq([ person.id ])
      end
    end
  end

  context "when setting new ids" do

    let!(:person) do
      Person.create
    end

    let!(:one) do
      Preference.create(name: "one")
    end

    let!(:two) do
      Preference.create(name: "two")
    end

    before do
      person.preference_ids = [ one.id, two.id ]
    end

    it "sets the foreign_key" do
      expect(person.preference_ids).to eq([ one.id, two.id ])
    end

    it "does not set the first inverse key" do
      expect(one.reload.person_ids).to be_empty
    end

    it "does not set the second inverse key" do
      expect(two.reload.person_ids).to be_empty
    end

    context "when saving the base" do

      context "when validation passes" do

        before do
          person.save
        end

        it "persists the foreign_key" do
          expect(person.reload.preference_ids).to eq([ one.id, two.id ])
        end

        it "sets the first inverse key" do
          expect(one.reload.person_ids).to eq([ person.id ])
        end

        it "sets the second inverse key" do
          expect(two.reload.person_ids).to eq([ person.id ])
        end
      end
    end
  end

  context "when replacing ids" do

    let!(:one) do
      Preference.create(name: "one")
    end

    let!(:two) do
      Preference.create(name: "two")
    end

    let!(:person) do
      Person.create(preference_ids: [ one.id, two.id ])
    end

    let!(:three) do
      Preference.create(name: "three")
    end

    before do
      person.preference_ids = [ three.id ]
    end

    it "sets the foreign_key" do
      expect(person.preference_ids).to eq([ three.id ])
    end

    it "does not remove the first inverse key" do
      expect(one.reload.person_ids).to eq([ person.id ])
    end

    it "does not remove the second inverse key" do
      expect(two.reload.person_ids).to eq([ person.id ])
    end

    it "does not set the third inverse key" do
      expect(three.reload.person_ids).to be_empty
    end

    context "when saving the base" do

      context "when validation passes" do

        before do
          person.save
        end

        it "persists the foreign_key" do
          expect(person.reload.preference_ids).to eq([ three.id ])
        end

        it "removes the first inverse key" do
          expect(one.reload.person_ids).to be_empty
        end

        it "removes the second inverse key" do
          expect(two.reload.person_ids).to be_empty
        end

        it "sets the third inverse key" do
          expect(three.reload.person_ids).to eq([ person.id ])
        end
      end
    end
  end

  context "when setting ids to empty" do

    let!(:one) do
      Preference.create(name: "one")
    end

    let!(:two) do
      Preference.create(name: "two")
    end

    let!(:person) do
      Person.create(preference_ids: [ one.id, two.id ])
    end

    before do
      person.preference_ids = []
    end

    it "sets the foreign_key" do
      expect(person.preference_ids).to be_empty
    end

    it "does not remove the first inverse key" do
      expect(one.reload.person_ids).to eq([ person.id ])
    end

    it "does not remove the second inverse key" do
      expect(two.reload.person_ids).to eq([ person.id ])
    end

    context "when saving the base" do

      context "when validation passes" do

        before do
          person.save
        end

        it "persists the foreign_key" do
          expect(person.reload.preference_ids).to be_empty
        end

        it "removes the first inverse key" do
          expect(one.reload.person_ids).to be_empty
        end

        it "removes the second inverse key" do
          expect(two.reload.person_ids).to be_empty
        end
      end
    end
  end

  context "when setting ids to nil" do

    let!(:one) do
      Preference.create(name: "one")
    end

    let!(:two) do
      Preference.create(name: "two")
    end

    let!(:person) do
      Person.create(preference_ids: [ one.id, two.id ])
    end

    before do
      person.preference_ids = nil
    end

    it "sets the foreign_key" do
      expect(person.preference_ids).to be_empty
    end

    it "does not remove the first inverse key" do
      expect(one.reload.person_ids).to eq([ person.id ])
    end

    it "does not remove the second inverse key" do
      expect(two.reload.person_ids).to eq([ person.id ])
    end

    context "when saving the base" do

      context "when validation passes" do

        before do
          person.save
        end

        it "persists the foreign_key" do
          expect(person.reload.preference_ids).to be_empty
        end

        it "removes the first inverse key" do
          expect(one.reload.person_ids).to be_empty
        end

        it "removes the second inverse key" do
          expect(two.reload.person_ids).to be_empty
        end
      end
    end
  end

  context "when destroying" do

    let!(:one) do
      Preference.create(name: "one")
    end

    let!(:two) do
      Preference.create(name: "two")
    end

    let!(:person) do
      Person.create(preferences: [ one, two ])
    end

    context "when destroying the parent" do

      before do
        person.destroy
      end

      it "removes the first inverse key" do
        expect(one.reload.person_ids).to be_empty
      end

      it "removes the second inverse key" do
        expect(two.reload.person_ids).to be_empty
      end
    end

    context "when destroying the child" do

      before do
        one.destroy
      end

      it "removes the inverse key" do
        expect(person.reload.preference_ids).to eq([ two.id ])
      end
    end
  end

  context "when appending an existing document to a new one" do

    let!(:persisted) do
      Tag.create
    end

    let(:article) do
      Article.new
    end

    before do
      article.tags << persisted
      article.save
    end

    it "persists the foreign key on the inverse" do
      expect(persisted.article_ids).to eq([ article.id ])
    end

    it "persists the inverse relation" do
      expect(persisted.articles).to eq([ article ])
    end
  end

  context "when the document has an ordering default scope" do

    let!(:dog) do
      Dog.create(name: "Fido")
    end

    let!(:breed) do
      Breed.new(dog_ids: [ dog.id ])
    end

    before do
      breed.save
    end

    it "adds the id to the inverse relation" do
      expect(dog.reload.breed_ids).to eq([ breed.id ])
    end
  end
end
