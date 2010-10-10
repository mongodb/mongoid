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

    before do
      person1 = Person.create(:title => "Sir", :age => 100, :aliases => ["D", "Durran"], :ssn => "666666666")
      person2 = Person.create(:title => "Madam", :age => 1, :ssn => "098-76-5434")

      person1.create_game(:score => 10)
      person2.create_game(:score => 20)
      
      person1.posts.create(:title => "post1")
      person1.posts.create(:title => "post2")
      person2.posts.create(:title => "post3")
      person2.posts.create(:title => "post4")
      
      person1.preferences.create(:name => "preference1")
      person1.preferences.create(:name => "preference2")
      person2.preferences.create(:name => "preference3")
      person2.preferences.create(:name => "preference4")
    end

    it "preload references_one association" do
      people = Person.all.to_a
      games = Game.all.to_a

      complex = stub(:key => :person_id, :operator => "in")
      Mongoid::Criterion::Complex.expects(:new).with(:key => :person_id, :operator => "in").returns(complex)
      Game.expects(:where).with(complex => people.collect(&:id)).returns(games)
      
      criteria = Mongoid::Criteria.new(Person)
      criteria.includes(:game)
      criteria.preload(people)

      people.first.game.should == games.first
      people.last.game.should == games.last
    end

    it "preload references_many association" do
      people = Person.all.to_a
      posts = Post.all.to_a
      person1_posts = Post.where(:person_id => people.first.id).to_a
      person2_posts = Post.where(:person_id => people.last.id).to_a

      complex = stub(:key => :person_id, :operator => "in")
      Mongoid::Criterion::Complex.expects(:new).with(:key => :person_id, :operator => "in").returns(complex)
      Post.expects(:where).with(complex => people.collect(&:id)).returns(posts)
      
      criteria = Mongoid::Criteria.new(Person)
      criteria.includes(:posts)
      criteria.preload(people)

      people.first.posts.should == person1_posts
      people.last.posts.should == person2_posts
    end

    it "preload references_many_as_array association" do
      people = Person.all.to_a
      preferences = Preference.all.to_a
      person1_preferences = Preference.find(people.first.preference_ids).to_a
      person2_preferences = Preference.find(people.last.preference_ids).to_a

      Preference.expects(:find).with(preferences.collect(&:id)).returns(preferences)

      criteria = Mongoid::Criteria.new(Person)
      criteria.includes(:preferences)
      criteria.preload(people)

      people.first.preferences.should == person1_preferences
      people.last.preferences.should == person2_preferences
    end

    it "preload referenced_in association" do
      people = Person.all.to_a
      games = Game.all.to_a

      Person.expects(:find).with(people.collect(&:id)).returns(people)
      
      criteria = Mongoid::Criteria.new(Game)
      criteria.includes(:person)
      criteria.preload(games)

      people.first.game.should == games.first
      people.last.game.should == games.last
    end
  end
end
