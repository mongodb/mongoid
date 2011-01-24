require "spec_helper"

describe Mongoid::Persistence::Update do

  before do
    Person.delete_all
  end

  after do
    Person.delete_all
  end

  describe "#persist" do

    let(:person) do
      Person.create!(:ssn => "111-11-1111", :title => "Sir")
    end

    context "when the document has changed" do

      before do
        @person = Person.find(person.id)
        @person.title = "Grand Poobah"
      end

      it "updates the document in the database" do
        update = Mongoid::Persistence::Update.new(@person)
        update.persist
        from_db = Person.find(@person.id)
        from_db.title.should == "Grand Poobah"
      end
    end

    context "when the document has not changed" do

      before do
        @person = Person.find(person.id)
      end

      it "returns true" do
        update = Mongoid::Persistence::Update.new(@person)
        update.persist.should == true
      end
    end
  end
end
