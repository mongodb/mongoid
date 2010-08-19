require "spec_helper"

describe Mongoid::Relations::Referenced::One do

  before do
    Person.delete_all
    Game.delete_all
  end

  # context "when building the relation" do

    # context "when the parent is a new record" do

      # it "sets the foreign key on the relation"
      # it "sets the base on the inverse relation"
      # it "does not save the target"
    # end

    # context "when the parent is not a new record" do

      # it "sets the target of the relation"
      # it "sets the foreign key of the relation"
      # it "sets the base on the inverse relation"
      # it "does not save the target"
    # end
  # end

  # context "when creating the relation" do

    # context "when the parent is a new record" do

      # it "sets the target of the relation"
      # it "sets the foreign key on the relation"
      # it "sets the base on the inverse relation"
      # it "does not save the target"
    # end

    # context "when the parent is not a new record" do

      # it "sets the target of the relation"
      # it "sets the foreign key of the relation"
      # it "sets the base on the inverse relation"
      # it "saves the target"
    # end
  # end

  context "when setting the relation" do

    context "when the parent is a new record" do

      let(:person) do
        Person.new
      end

      let(:game) do
        Game.new
      end

      before do
        person.game = game
      end

      it "sets the target of the relation" do
        person.game.target.should == game
      end

      it "sets the foreign key on the relation" do
        game.person_id.should == person.id
      end

      it "sets the base on the inverse relation" do
        game.person.should == person
      end

      it "does not save the target" do
        game.should_not be_persisted
      end
    end

    context "when the parent is not a new record" do

      let(:person) do
        Person.create(:ssn => "437-11-1112")
      end

      let(:game) do
        Game.new
      end

      before do
        person.game = game
      end

      it "sets the target of the relation" do
        person.game.target.should == game
      end

      it "sets the foreign key of the relation" do
        game.person_id.should == person.id
      end

      it "sets the base on the inverse relation" do
        game.person.should == person
      end

      it "saves the target" do
        game.should be_persisted
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
        person.game = game
        person.game = nil
      end

      it "sets the relation to nil" do
        person.game.should be_nil
      end

      it "removed the inverse relation" do
        game.person.should be_nil
      end

      it "removes the foreign key value" do
        game.person_id.should be_nil
      end
    end

    context "when the parent is not a new record" do

      let(:person) do
        Person.create(:ssn => "437-11-1112")
      end

      let(:game) do
        Game.new
      end

      before do
        person.game = game
        person.game = nil
      end

      it "sets the relation to nil" do
        person.game.should be_nil
      end

      it "removed the inverse relation" do
        game.person.should be_nil
      end

      it "removes the foreign key value" do
        game.person_id.should be_nil
      end

      it "deletes the target from the database" do
        game.should be_destroyed
      end
    end
  end
end
