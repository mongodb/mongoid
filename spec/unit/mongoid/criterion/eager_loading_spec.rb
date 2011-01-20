require "spec_helper"

describe Mongoid::Criterion::EagerLoading do

  describe "#includes" do

    it "should return self" do
      criteria = Mongoid::Criteria.new(Person)
      criteria.includes(:game, :posts).should == criteria
    end

    it "set eager loadings" do
      criteria = Mongoid::Criteria.new(Person)
      criteria.includes(:game, :posts)
      criteria.eager_loadings.should == [:game, :posts]
    end
  end

  describe "#preload" do

    before :all do
      Preference.destroy_all
      Post.destroy_all
      Game.destroy_all
      Person.destroy_all

      @person1 = Person.create(:title => "Sir", :age => 100, :aliases => ["D", "Durran"], :ssn => "666666666")
      @person2 = Person.create(:title => "Madam", :age => 1, :ssn => "098-76-5434")
      @person3 = Person.create(:title => "Sir", :age => 10, :aliases => ["R", "Richard"], :ssn => "111111111")

      @game1 = @person1.create_game(:score => 10)
      @game2 = @person2.create_game(:score => 20)
      @game3 = Game.create(:score => 30)

      @post1 = @person1.posts.create(:title => "post1")
      @post2 = @person1.posts.create(:title => "post2")
      @post3 = @person2.posts.create(:title => "post3")
      @post4 = @person2.posts.create(:title => "post4")
      @post5 = Post.create(:title => "post5")

      @preference1 = @person1.preferences.create(:name => "preference1")
      @preference2 = @person1.preferences.create(:name => "preference2")
      @preference3 = @person2.preferences.create(:name => "preference3")
      @preference4 = @person2.preferences.create(:name => "preference4")
      @preference5 = Preference.create(:name => "preference5")
    end

    it "preload references_one association" do
      people = Person.all.to_a
      games = Game.all.to_a

      criteria = Mongoid::Criteria.new(Person)
      criteria.includes(:game)
      criteria.preload(people)

      id_documents_map = criteria.send(:id_documents_map)
      id_documents_map[@person1.id].should == [@person1]
      id_documents_map[@person2.id].should == [@person2]
      id_documents_map[@person3.id].should == [@person3]

      id_associations_map = criteria.send(:id_associations_map)
      id_associations_map[@person1.id].should == [@game1]
      id_associations_map[@person2.id].should == [@game2]
      id_associations_map[@person3.id].should == nil

      @person1.game.should == @game1
      @person2.game.should == @game2
      @person3.game.should == nil
    end

    it "preload references_many association" do
      people = Person.all.to_a
      posts = Post.all.to_a

      criteria = Mongoid::Criteria.new(Person)
      criteria.includes(:posts)
      criteria.preload(people)

      id_documents_map = criteria.send(:id_documents_map)
      id_documents_map[@person1.id].should == [@person1]
      id_documents_map[@person2.id].should == [@person2]
      id_documents_map[@person3.id].should == [@person3]

      id_associations_map = criteria.send(:id_associations_map)
      id_associations_map[@person1.id].should == [@post1, @post2]
      id_associations_map[@person2.id].should == [@post3, @post4]
      id_associations_map[@person3.id].should == nil

      @person1.posts.should == [@post1, @post2]
      @person2.posts.should == [@post3, @post4]
      @person3.posts.should == []
    end

    it "preload references_many_as_array association" do
      people = Person.all.to_a
      preferences = Preference.all.to_a

      criteria = Mongoid::Criteria.new(Person)
      criteria.includes(:preferences)
      criteria.preload(people)

      id_documents_map = criteria.send(:id_documents_map)
      id_documents_map[@preference1.id].should == [@person1]
      id_documents_map[@preference2.id].should == [@person1]
      id_documents_map[@preference3.id].should == [@person2]
      id_documents_map[@preference4.id].should == [@person2]
      id_documents_map[@preference5.id].should == nil

      id_associations_map = criteria.send(:id_associations_map)
      id_associations_map[@preference1.id].should == [@preference1]
      id_associations_map[@preference2.id].should == [@preference2]
      id_associations_map[@preference3.id].should == [@preference3]
      id_associations_map[@preference4.id].should == [@preference4]
      id_associations_map[@preference5.id].should == nil

      @person1.preferences.should == [@preference1, @preference2]
      @person2.preferences.should == [@preference3, @preference4]
      @person3.preferences.should == []
    end

    context "referenced_in" do
      it "preload referenced_in association to references_one" do
        people = Person.all.to_a
        games = Game.all.to_a

        criteria = Mongoid::Criteria.new(Game)
        criteria.includes(:person)
        criteria.preload(games)

        id_documents_map = criteria.send(:id_documents_map)
        id_documents_map[@person1.id].should == [@game1]
        id_documents_map[@person2.id].should == [@game2]
        id_documents_map[@person3.id].should == nil

        id_associations_map = criteria.send(:id_associations_map)
        id_associations_map[@person1.id].should == [@person1]
        id_associations_map[@person2.id].should == [@person2]
        id_associations_map[@person3.id].should == nil

        @game1.person.should == @person1
        @game2.person.should == @person2
        @game3.person.should == nil
      end

      it "preload referenced_in association to references_many" do
        people = Person.all.to_a
        posts = Post.all.to_a

        criteria = Mongoid::Criteria.new(Game)
        criteria.includes(:person)
        criteria.preload(posts)

        id_documents_map = criteria.send(:id_documents_map)
        id_documents_map[@person1.id].should == [@post1, @post2]
        id_documents_map[@person2.id].should == [@post3, @post4]
        id_documents_map[@person3.id].should == nil

        id_associations_map = criteria.send(:id_associations_map)
        id_associations_map[@person1.id].should == [@person1]
        id_associations_map[@person2.id].should == [@person2]
        id_associations_map[@person3.id].should == nil

        @post1.person.should == @person1
        @post2.person.should == @person1
        @post3.person.should == @person2
        @post4.person.should == @person2
        @post5.person.should == nil
      end
    end
  end
end
