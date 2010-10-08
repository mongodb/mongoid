require "spec_helper"

describe Mongoid::Criterion::EagerLoading do

  describe "#includes" do
    
    it "should return self" do
      criteria = Mongoid::Criteria.new(Person)
      criteria.includes(:game).should == criteria
    end

    it "set eager loadings" do
      criteria = Mongoid::Criteria.new(Person)
      criteria.includes(:game)
      criteria.eager_loadings.should == [:game]
    end
  end

  describe "#preload" do
    let(:person1) { Person.create(:title => "Sir", :age => 100, :aliases => ["D", "Durran"], :ssn => "666666666") }
    let(:person2) { Person.create(:title => "Madam", :age => 1, :ssn => "098-76-5434") }

    before do
      person1.create_game(:score => 10)
      person2.create_game(:score => 20)
    end

    it "preload references_one association" do
      complex = stub(:key => :person_id, :operator => "in")
      Mongoid::Criterion::Complex.expects(:new).with(:key => :person_id, :operator => "in").returns(complex)
      Game.expects(:where).with(complex => [person1.id, person2.id]).returns([person1.game, person2.game])
      criteria = Mongoid::Criteria.new(Person)
      criteria.includes(:game)
      criteria.preload([person1, person2])
    end

    it "preload referenced_in association" do
      criteria = Mongoid::Criteria.new(Game)
      documents = [person1.game, person2.game]
      Person.expects(:find).with([person1.id, person2.id]).returns([person1, person2])
      criteria.includes(:person)
      criteria.preload(documents)
    end
  end
  
  describe "#association_reflection" do
    let(:person1) { Person.create(:title => "Sir", :age => 100, :aliases => ["D", "Durran"], :ssn => "666666666") }
    let(:person2) { Person.create(:title => "Madam", :age => 1, :ssn => "098-76-5434") }

    before do
      person1.create_game(:score => 10)
      person2.create_game(:score => 20)
    end
    
    it "with referenced_in" do
      criteria = Mongoid::Criteria.new(Person)
      criteria.includes(:game)
      reflection = criteria.association_reflection(Person, :game)
      reflection.foreign_key.should == "person_id"
      reflection.name.should == "game"
    end
  end
end
