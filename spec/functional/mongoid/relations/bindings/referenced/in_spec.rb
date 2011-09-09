require "spec_helper"

describe Mongoid::Relations::Bindings::Referenced::One do

  describe "#bind" do

    let(:person) do
      Person.new
    end

    context "when the child is frozen" do

      let(:game) do
        Game.new.freeze
      end

      before do
        game.person = person
      end

      it "does not set the foreign key" do
        game.person_id.should be_nil
      end
    end
  end

  describe "#unbind" do

    let(:person) do
      Person.new
    end

    context "when the child is frozen" do

      let(:game) do
        Game.new
      end

      before do
        game.person = person
        game.freeze
        game.person = nil
      end

      it "does not unset the foreign key" do
        game.person_id.should eq(person.id)
      end
    end
  end
end
