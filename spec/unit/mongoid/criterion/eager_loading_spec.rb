require "spec_helper"

describe Mongoid::Criterion::EagerLoading do

  describe "#includes" do

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

    it "preload references_in association" do
      complex = stub(:key => :person_id, :operator => "in")
      Mongoid::Criterion::Complex.expects(:new).with(:key => :person_id, :operator => "in").returns(complex)
      Game.expects(:where).with(complex => [person1.id, person2.id]).returns([person1.game, person2.game])
      criteria = Mongoid::Criteria.new(Person)
      documents = Person.all.to_a
      criteria.includes(:game)
      criteria.preload(documents)
    end
  end
end
