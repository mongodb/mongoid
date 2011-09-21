require "spec_helper"

describe Mongoid::Relations::Synchronization do

  before do
    [ Person, Preference, Article, Tag ].each(&:delete_all)
  end

  context "when first setting by the relation itself" do

    let!(:person) do
      Person.create(:ssn => "342-12-2222")
    end

    let!(:one) do
      Preference.create(:name => "one")
    end

    before do
      person.preferences << one
    end

    it "sets the inverse foreign key" do
      one.person_ids.should eq([ person.id ])
    end

    it "resets the synced flag" do
      person.synced["preference_ids"].should be_false
    end

    context "when subsequently setting with keys" do

      let!(:two) do
        Preference.create(:name => "two")
      end

      before do
        person.preference_ids << two.id
        person.save
      end

      it "sets the inverse foreign key" do
        two.reload.person_ids.should eq([ person.id ])
      end
    end
  end

  context "when setting new ids" do

    let!(:person) do
      Person.create(:ssn => "342-12-2222")
    end

    let!(:one) do
      Preference.create(:name => "one")
    end

    let!(:two) do
      Preference.create(:name => "two")
    end

    before do
      person.preference_ids = [ one.id, two.id ]
    end

    it "sets the foreign_key" do
      person.preference_ids.should eq([ one.id, two.id ])
    end

    it "does not set the first inverse key" do
      one.reload.person_ids.should be_empty
    end

    it "does not set the second inverse key" do
      two.reload.person_ids.should be_empty
    end

    context "when saving the base" do

      context "when validation passes" do

        before do
          person.save
        end

        it "persists the foreign_key" do
          person.reload.preference_ids.should eq([ one.id, two.id ])
        end

        it "sets the first inverse key" do
          one.reload.person_ids.should eq([ person.id ])
        end

        it "sets the second inverse key" do
          two.reload.person_ids.should eq([ person.id ])
        end
      end
    end
  end

  context "when replacing ids" do

    let!(:one) do
      Preference.create(:name => "one")
    end

    let!(:two) do
      Preference.create(:name => "two")
    end

    let!(:person) do
      Person.create(
        :ssn => "342-12-2222",
        :preference_ids => [ one.id, two.id ]
      )
    end

    let!(:three) do
      Preference.create(:name => "three")
    end

    before do
      person.preference_ids = [ three.id ]
    end

    it "sets the foreign_key" do
      person.preference_ids.should eq([ three.id ])
    end

    it "does not remove the first inverse key" do
      one.reload.person_ids.should eq([ person.id ])
    end

    it "does not remove the second inverse key" do
      two.reload.person_ids.should eq([ person.id ])
    end

    it "does not set the third inverse key" do
      three.reload.person_ids.should be_empty
    end

    context "when saving the base" do

      context "when validation passes" do

        before do
          person.save
        end

        it "persists the foreign_key" do
          person.reload.preference_ids.should eq([ three.id ])
        end

        it "removes the first inverse key" do
          one.reload.person_ids.should be_empty
        end

        it "removes the second inverse key" do
          two.reload.person_ids.should be_empty
        end

        it "sets the third inverse key" do
          three.reload.person_ids.should eq([ person.id ])
        end
      end
    end
  end

  context "when setting ids to empty" do

    let!(:one) do
      Preference.create(:name => "one")
    end

    let!(:two) do
      Preference.create(:name => "two")
    end

    let!(:person) do
      Person.create(
        :ssn => "342-12-2222",
        :preference_ids => [ one.id, two.id ]
      )
    end

    before do
      person.preference_ids = []
    end

    it "sets the foreign_key" do
      person.preference_ids.should be_empty
    end

    it "does not remove the first inverse key" do
      one.reload.person_ids.should eq([ person.id ])
    end

    it "does not remove the second inverse key" do
      two.reload.person_ids.should eq([ person.id ])
    end

    context "when saving the base" do

      context "when validation passes" do

        before do
          person.save
        end

        it "persists the foreign_key" do
          person.reload.preference_ids.should be_empty
        end

        it "removes the first inverse key" do
          one.reload.person_ids.should be_empty
        end

        it "removes the second inverse key" do
          two.reload.person_ids.should be_empty
        end
      end
    end
  end

  context "when setting ids to nil" do

    let!(:one) do
      Preference.create(:name => "one")
    end

    let!(:two) do
      Preference.create(:name => "two")
    end

    let!(:person) do
      Person.create(
        :ssn => "342-12-2222",
        :preference_ids => [ one.id, two.id ]
      )
    end

    before do
      person.preference_ids = nil
    end

    it "sets the foreign_key" do
      person.preference_ids.should be_empty
    end

    it "does not remove the first inverse key" do
      one.reload.person_ids.should eq([ person.id ])
    end

    it "does not remove the second inverse key" do
      two.reload.person_ids.should eq([ person.id ])
    end

    context "when saving the base" do

      context "when validation passes" do

        before do
          person.save
        end

        it "persists the foreign_key" do
          person.reload.preference_ids.should be_empty
        end

        it "removes the first inverse key" do
          one.reload.person_ids.should be_empty
        end

        it "removes the second inverse key" do
          two.reload.person_ids.should be_empty
        end
      end
    end
  end

  context "when destroying" do

    let!(:one) do
      Preference.create(:name => "one")
    end

    let!(:two) do
      Preference.create(:name => "two")
    end

    let!(:person) do
      Person.create(
        :ssn => "342-12-2222",
        :preferences => [ one, two ]
      )
    end

    context "when destroying the parent" do

      before do
        person.destroy
      end

      it "removes the first inverse key" do
        one.reload.person_ids.should be_empty
      end

      it "removes the second inverse key" do
        two.reload.person_ids.should be_empty
      end
    end

    context "when destroying the child" do

      before do
        one.destroy
      end

      it "removes the inverse key" do
        person.reload.preference_ids.should eq([ two.id ])
      end
    end
  end

  context "when appending an existing document to a new one" do

    let!(:peristed) do
      Tag.create
    end

    let(:article) do
      Article.new
    end

    before do
      article.tags << Tag.first
      article.save
    end

    let(:tag) do
      Tag.first
    end

    it "persists the foreign key on the inverse" do
      tag.article_ids.should eq([ article.id ])
    end

    it "persists the inverse relation" do
      tag.articles.should eq([ article ])
    end
  end
end
