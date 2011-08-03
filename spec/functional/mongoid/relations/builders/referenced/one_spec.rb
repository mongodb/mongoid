require "spec_helper"

describe Mongoid::Relations::Builders::Referenced::One do

  before do
    [ Person, Game ].each(&:delete_all)
  end

  describe "#build" do

    let(:person) do
      Person.new(:ssn => "345-12-1212")
    end

    context "when the document is not found" do

      it "returns nil" do
        person.game.should be_nil
      end
    end

    context "when the document is persisted" do

      before do
        Mongoid.identity_map_enabled = true
        person.save
      end

      after do
        Mongoid.identity_map_enabled = false
      end

      let!(:game) do
        Game.create(:person_id => person.id)
      end

      it "returns the document" do
        person.game.should eq(game)
      end

      it "pulls the document from the identity map" do
        person.game.should equal(game)
      end
    end
  end
end
