require "spec_helper"

describe Mongoid::Relations::Builders::Referenced::In do

  before do
    [ Person, Game ].each(&:delete_all)
  end

  describe "#build" do

    let(:game) do
      Game.new
    end

    context "when no document found in the database" do

      context "when the id is nil" do

        it "returns nil" do
          game.person.should be_nil
        end
      end

      context "when the id is incorrect" do

        before do
          game.person_id = BSON::ObjectId.new
        end

        it "returns nil" do
          game.person.should be_nil
        end
      end
    end

    context "when the document is persisted" do

      before do
        Mongoid.identity_map_enabled = true
      end

      let!(:person) do
        Person.create(:ssn => "456-11-1123")
      end

      let(:game) do
        Game.new(:person_id => person.id)
      end

      after do
        Mongoid.identity_map_enabled = false
      end

      it "returns the document" do
        game.person.should eq(person)
      end

      it "gets the document from the identity map" do
        game.person.should equal(person)
      end
    end

    context 'setting an associated document to nil' do
      let(:person) { Person.create }
      let(:game) { Game.create(:person => person) }

      before do
        game.person = nil
        game.save
      end

      it 'sets the person_id to nil' do
        game.person_id.should be_nil
      end

      it 'does not delete the person' do
        Person.find(person.id).should == person
      end
    end
  end

  describe '#substitute' do
    let(:person) { Person.create }
    let(:game) { Game.create(:person => person) }

    context 'setting an associated document to nil' do
      before do
        game.person = nil
      end

      it 'sets the person_id to nil' do
        game.person_id.should be_nil
      end

      it 'does not delete the person' do
        Person.find(person.id).should == person
      end
    end

    context 'setting an associated document to nil' do
      let(:other_person) { Person.create }
      before do
        game.person = other_person
      end

      it 'sets the person_id to nil' do
        game.person_id.should == other_person.id
      end

      it 'does not delete the person' do
        Person.find(person.id).should == person
      end
    end
  end
end
