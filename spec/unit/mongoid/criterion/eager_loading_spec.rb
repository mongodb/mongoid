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
    let(:person1) { Person.create(:title => "Sir", :age => 100, :aliases => ["D", "Durran"], :ssn => "666666666") }
    let(:person2) { Person.create(:title => "Madam", :age => 1, :ssn => "098-76-5434") }

    before do
      person1.create_game(:score => 10)
      person2.create_game(:score => 20)
      
      person1.posts.create(:title => "post1")
      person1.posts.create(:title => "post2")
      person2.posts.create(:title => "post3")
      person2.posts.create(:title => "post4")
    end

    it "preload references_one association" do
      complex = stub(:key => :person_id, :operator => "in")
      Mongoid::Criterion::Complex.expects(:new).with(:key => :person_id, :operator => "in").returns(complex)
      Game.expects(:where).with(complex => [person1.id, person2.id]).returns([person1.game, person2.game])
      
      criteria = Mongoid::Criteria.new(Person)
      criteria.includes(:game)
      criteria.preload([person1, person2])
    end

    it "preload references_many association" do
      complex = stub(:key => :person_id, :operator => "in")
      Mongoid::Criterion::Complex.expects(:new).with(:key => :person_id, :operator => "in").returns(complex)
      Post.expects(:where).with(complex => [person1.id, person2.id]).returns(person1.posts + person2.posts)
      
      criteria = Mongoid::Criteria.new(Person)
      criteria.includes(:posts)
      criteria.preload([person1, person2])
    end

    it "preload referenced_in association" do
      Person.expects(:find).with([person1.id, person2.id]).returns([person1, person2])
      
      criteria = Mongoid::Criteria.new(Game)
      criteria.includes(:person)
      criteria.preload([person1.game, person2.game])
    end
  end
  
  describe "#association_reflection" do

    it "with references_one" do
      criteria = Mongoid::Criteria.new(Person)
      reflection = criteria.association_reflection(Person, :game)
      reflection.association.should == Mongoid::Associations::ReferencesOne
      reflection.foreign_key.should == "person_id"
      reflection.name.should == "game"
    end
    
    it "with references_many" do
      criteria = Mongoid::Criteria.new(Person)
      reflection = criteria.association_reflection(Person, :posts)
      reflection.association.should == Mongoid::Associations::ReferencesMany
      reflection.foreign_key.should == "person_id"
      reflection.name.should == "posts"
    end
    
    it "with referenced_in" do
      criteria = Mongoid::Criteria.new(Game)
      reflection = criteria.association_reflection(Game, :person)
      reflection.association.should == Mongoid::Associations::ReferencedIn
      reflection.foreign_key.should == "person_id"
      reflection.name.should == "person"
    end
  end
end
