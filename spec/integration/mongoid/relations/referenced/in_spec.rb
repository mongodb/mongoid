require "spec_helper"

describe Mongoid::Relations::Referenced::In do

  before do
    Person.delete_all
    Game.delete_all
  end

  context "when setting the relation" do

    context "when the child is a new record" do

      let(:person) do
        Person.new
      end

      let(:game) do
        Game.new
      end

      before do
        game.person = person
      end

      it "sets the target of the relation" do
        game.person.target.should == person
      end

      it "sets the foreign key on the relation" do
        game.person_id.should == person.id
      end

      it "sets the base on the inverse relation" do
        person.game.should == game
      end

      it "does not save the target" do
        person.should_not be_persisted
      end
    end

    context "when the child is not a new record" do

      let(:person) do
        Person.new(:ssn => "437-11-1112")
      end

      let(:game) do
        Game.create
      end

      before do
        game.person = person
      end

      it "sets the target of the relation" do
        game.person.target.should == person
      end

      it "sets the foreign key of the relation" do
        game.person_id.should == person.id
      end

      it "sets the base on the inverse relation" do
        person.game.should == game
      end

      it "saves the target" do
        person.should be_persisted
      end
    end
  end

  context "when removing the relation" do

    context "when the parent is a new record" do

      let(:person) do
        Person.new
      end

      let(:game) do
        Game.new
      end

      before do
        game.person = person
        game.person = nil
      end

      it "sets the relation to nil" do
        game.person.should be_nil
      end

      it "removed the inverse relation" do
        person.game.should be_nil
      end

      it "removes the foreign key value" do
        game.person_id.should be_nil
      end
    end

    context "when the parent is not a new record" do

      let(:person) do
        Person.new(:ssn => "437-11-1112")
      end

      let(:game) do
        Game.create
      end

      before do
        game.person = person
        game.person = nil
      end

      it "sets the relation to nil" do
        game.person.should be_nil
      end

      it "removed the inverse relation" do
        person.game.should be_nil
      end

      it "removes the foreign key value" do
        game.person_id.should be_nil
      end
    end
  end
end
